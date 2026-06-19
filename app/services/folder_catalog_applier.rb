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
    # The Text model requires at least one title; fall back to the folder name.
    if text.title_tibetan.blank? && text.title_phonetics.blank? && text.title_wylie.blank?
      text.title_phonetics = File.basename(@proposal.folder_path)
    end
    assign_lookups(text, group)
    text.save!
    text
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
  # creates the record when no match exists.
  def lookup_ids(klass, name_field, names)
    Array(names).filter_map { |name|
      key = squash(name)
      next if key.blank?

      record   = klass.all.find { |r| squash(r.public_send(name_field)) == key }
      record ||= klass.create!(name_field => name.strip)
      record.id
    }
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
