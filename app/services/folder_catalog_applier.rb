# Applies a FolderTriageProposal to the catalog: creates or links
# Text → Translation → Version entries from the proposal's groups.
#
# Text deduplication order:
#   1. existing_text_id chosen by the AI (verified)
#   2. normalized Tibetan title (cross-language join key)
#   3. normalized Wylie title
#   4. translated title (case/accent-insensitive)
#
# Only files with role "version" become Versions and get their CataloguedFile
# linked + triaged. working/fragment/noise files stay pending — they are listed
# in the proposal payload for later review.
class FolderCatalogApplier
  # Le modèle liste volontiers tout ce qu'un texte mentionne (lignées entières,
  # catégories d'êtres). On ne garde que les entités nommées : au-delà, le
  # référentiel devient inutilisable comme facette de recherche.
  MAX_LOOKUPS_PER_KIND = 3

  # Termes génériques : des catégories, pas des noms propres. Le corpus est
  # multilingue (fr/en/es/pt) — les catégories apparaissent dans chaque langue.
  GENERIC_LOOKUP_RE = /\A(
    (local\s+)?(deities|deity|gods?|goddess(es)?|spirits?|ghosts?|demons?|nagas?) |
    dakas?(\s+and\s+dakinis?)? | dakinis? | yidam(\s+deities)? | protectors? | guardians? |
    (three\s+)?(jewels?|roots?) | sugatas? | lama | buddhas? | bodhisattvas? |
    (all\s+)?(beings?|masters?|teachers?) | those\s+.* | spirits\s+of\s+.* | .*\s+guardians? |
    # français
    (les\s+)?(dieux|d[ée]it[ée]s?|esprits?|d[ée]mons?|protecteurs?|gardiens?|ma[îi]tres?) |
    (les\s+)?(trois\s+)?(joyaux|racines) | (le\s+)?(roi|reine)\s+des?\s+.* |
    # espagnol et portugais
    (los\s+|las\s+)?(dioses|deidades?|esp[ií]ritus?|demonios?|protectores?|guardianes?|maestros?|nagas) |
    (las\s+)?(tres\s+)?(joyas|ra[ií]ces) | (el\s+)?(rey|reina)\s+de\s+.* |
    (ocho|cinco|cuatro|tres|dos|doce|veintiuna?)\s+.*
  )\z/xi

  # Noms de dossiers de travail : ne doivent jamais devenir un titre de texte.
  GENERIC_FOLDER_NAMES = [
    "travail", "old", "archives", "archive", "divers", "a classer", "corbeille",
    "mesdocs", "outils", "temp", "tmp", "backup", "copie", "nouveau dossier"
  ].freeze

  LANGUAGE_CANON = {
    "french" => "French", "francais" => "French",
    "english" => "English",
    "tibetan" => "Tibetan",
    "spanish" => "Spanish", "espanol" => "Spanish", "espagnol" => "Spanish",
    "portuguese" => "Portuguese", "portugues" => "Portuguese",
    "finnish" => "Finnish",
    "sanskrit" => "Sanskrit"
  }.freeze

  Result = Data.define(:texts, :versions_count, :error)

  def initialize(proposal)
    @proposal = proposal
  end

  def call
    texts = []
    versions_count = 0

    ActiveRecord::Base.transaction do
      @proposal.groups.each do |group|
        version_files = files_for(group, role: "version")
        next if version_files.empty?

        text        = resolve_text(group)
        language    = resolve_language(group["language"])
        translation = text.translations.find_or_create_by!(language: language)

        version_files.each do |cf, label|
          version = translation.versions.find_or_create_by!(name: label) { |v| v.status = :draft }
          cf.update!(version_id: version.id, triage_state: :triaged)
          versions_count += 1
        end
        texts << text
      end

      @proposal.update!(status: :applied)
    end

    Result.new(texts: texts.uniq, versions_count: versions_count, error: nil)
  rescue => e
    Rails.logger.error("[FolderCatalogApplier] failed for proposal #{@proposal.id}: #{e.message}")
    @proposal.update(status: :failed, error: e.message)
    Result.new(texts: [], versions_count: 0, error: e.message)
  end

  private

  # Returns [[catalogued_file, version_label], ...] for the requested role.
  def files_for(group, role:)
    Array(group["files"]).filter_map do |f|
      next unless f["role"] == role

      cf = CataloguedFile.find_by(id: f["id"])
      next unless cf
      next if cf.triaged? # already linked by an earlier folder

      label = f["version_label"].presence || cf.active_locations.first&.filename || "Version"
      [ cf, label ]
    end
  end

  def resolve_text(group)
    # Reclassify AI titles before using them as keys: fake Tibetan/Wylie would
    # otherwise poison the cross-language join.
    titles = TibetanText.sanitize_titles(
      group["title_tibetan"], group["title_wylie"], group["title_translated"]
    )
    group = group.merge(
      "title_tibetan"    => titles[:tibetan],
      "title_wylie"      => titles[:wylie],
      "title_translated" => titles[:phonetic]
    )

    tib_key   = TibetanText.normalize(group["title_tibetan"])
    wylie_key = squash(group["title_wylie"])
    trans_key = squash(group["title_translated"])

    text   = Text.find_by(id: group["existing_text_id"]) if group["existing_text_id"]
    text ||= Text.find_by(title_tibetan_normalized: tib_key) if tib_key
    text ||= Text.all.find { |t| squash(t.title_wylie) == wylie_key } if wylie_key
    text ||= Text.all.find { |t| squash(t.title_phonetics) == trans_key } if trans_key

    if text
      enrich_text(text, group, tib_key)
    else
      text = create_text(group, tib_key)
    end
    text
  end

  def create_text(group, tib_key)
    text = Text.new(
      title_tibetan:            group["title_tibetan"].presence,
      title_wylie:              group["title_wylie"].presence,
      title_phonetics:          group["title_translated"].presence,
      title_tibetan_normalized: tib_key
    )
    # Le modèle exige au moins un titre. À défaut, on se rabat sur le nom du
    # PREMIER FICHIER du groupe (informatif), jamais sur le nom du dossier :
    # un dossier "Travail"/"OLD" produirait un texte intitulé "Travail".
    if text.title_tibetan.blank? && text.title_phonetics.blank? && text.title_wylie.blank?
      text.title_phonetics = fallback_title(group)
    end
    assign_lookups(text, group)
    text.save!
    text
  end

  # Nom de fichier (sans extension) du premier fichier du groupe, à défaut le
  # nom du dossier — mais jamais un nom de dossier de travail générique.
  def fallback_title(group)
    first_id = Array(group["files"]).first&.dig("id")
    from_file = CataloguedFile.find_by(id: first_id)&.active_locations&.first&.filename
    return File.basename(from_file, ".*") if from_file.present?

    folder = File.basename(@proposal.folder_path)
    GENERIC_FOLDER_NAMES.include?(squash(folder)) ? "Sans titre — #{@proposal.folder_path}" : folder
  end

  # A text first created from a non-Tibetan folder may lack Tibetan titles;
  # fill them in when another language's group knows them. The normalized key
  # is the cross-language join key: never stamp one that another Text already
  # holds, or two distinct texts become unmergeable duplicates of that key.
  def enrich_text(text, group, tib_key)
    if tib_key && text.title_tibetan_normalized.blank? &&
       !Text.where.not(id: text.id).exists?(title_tibetan_normalized: tib_key)
      text.title_tibetan            = group["title_tibetan"]
      text.title_tibetan_normalized = tib_key
    end
    text.title_wylie ||= group["title_wylie"].presence
    assign_lookups(text, group)
    text.save! if text.changed?
  end

  def assign_lookups(text, group)
    text.author_ids |= lookup_ids(Author, :name_english, group["authors"])
    text.deity_ids  |= lookup_ids(Deity,  :name_english, group["deities"])
    text.school_ids |= lookup_ids(School, :name,         group["schools"])
  end

  # Accent/case-insensitive match against existing lookup records;
  # creates the record when no match exists. Les entrées génériques ou
  # descriptives sont écartées, et on plafonne le nombre retenu.
  def lookup_ids(klass, name_field, names)
    Array(names).filter_map { |name|
      key = squash(name)
      next if key.blank? || generic_lookup?(name)

      record   = klass.all.find { |r| squash(r.public_send(name_field)) == key }
      record ||= klass.create!(name_field => name.strip)
      record.id
    }.first(MAX_LOOKUPS_PER_KIND)
  end

  # Écarte les catégories ("gods", "dakinis"), les descriptions à rallonge
  # ("Lady who Strikes down Malignant Armies") et les épithètes non nominatives.
  def generic_lookup?(name)
    n = name.to_s.strip
    return true if n.length > 48
    return true if n.split.size > 4 # une description, pas un nom

    # "gods and ghosts", "dakas and dakinis" : générique si TOUS les composants
    # le sont (sinon "Tara and Chenrezig" serait écarté à tort).
    parts = n.split(/\s+and\s+|\s*&\s*|\s*,\s*/i).map(&:strip).reject(&:blank?)
    return true if parts.any? && parts.all? { |part| part.match?(GENERIC_LOOKUP_RE) }

    false
  end

  def resolve_language(name)
    canon = LANGUAGE_CANON.fetch(squash(name).to_s, "Other")
    Language.find_or_create_by!(name: canon)
  end

  def squash(str)
    return nil if str.blank?

    I18n.transliterate(str.strip).downcase.gsub(/\s+/, " ").presence
  end
end
