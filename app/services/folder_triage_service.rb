require "json"

# Folder-level AI triage: analyses one NAS folder as a unit, using the per-file
# cards built by FileCardService, and proposes groups of files that form
# Text → Translation → Version entries.
#
# The folder is the primary grouping signal (the archive is already organised
# by text and language); file content (cards) is the cross-check. The service
# also receives the existing Texts so the AI can link a folder to an
# already-catalogued text across languages.
#
# Creates a FolderTriageProposal; applying it to the catalog is
# FolderCatalogApplier's job.
class FolderTriageService
  MAX_EXISTING_TEXTS = 150

  # Extensions that can never be a catalog version: fonts, archives, layout
  # sidecars, thumbnails, OS junk. Excluded from the AI call and auto-listed
  # as unassigned, so they never get sent for analysis or become versions.
  NOISE_EXTENSIONS = %w[
    .ttf .otf .pfb .pfm .afm .ttc
    .zip .rar .7z .gz .sit
    .db .ds_store .tmp .lnk
    .sty .dct .cap .cif .chp .cch .wpm .wa0 .p .pub .qxd
  ].freeze

  # Filenames that look like imposition/printing spreads or single extracted
  # pages of a larger document — these are fragments, not standalone texts.
  IMPOSITION_PATTERN = /(?:\b\d{1,2}[_-]\d{1,2}\b|\bp\.?\s?\d{1,3}\b|\bpage\s?\d+\b)/i

  Result = Data.define(:proposal, :error)

  # folder_path: absolute path of the folder; files: CataloguedFiles whose
  # active location sits directly in that folder.
  def initialize(folder_path, files, adapter: nil)
    @folder_path = folder_path
    @files       = files
    @adapter     = adapter
  end

  def call
    @noise, @analysable = @files.partition { |cf| noise?(cf) }

    # A folder of pure noise (fonts, archives) yields an empty proposal — no
    # AI call needed.
    if @analysable.empty?
      proposal = FolderTriageProposal.create!(
        folder_path: relative_folder, status: :proposed,
        payload: { "groups" => [], "unassigned_file_ids" => @noise.map(&:id),
                   "notes" => "Aucun fichier analysable (bruit uniquement)." }
      )
      return Result.new(proposal: proposal, error: nil)
    end

    response = adapter.messages(
      model_tier: :fast,
      max_tokens: 4096,
      system:     system_prompt,
      messages:   [ { role: "user", content: user_prompt } ]
    )

    raw_text = response.content.first.text
    payload  = parse_response(raw_text)
    payload  = append_noise(payload) if payload

    proposal = FolderTriageProposal.create!(
      folder_path: relative_folder,
      status:      payload ? :proposed : :failed,
      payload:     payload,
      model_used:  response.model_used,
      error:       payload ? nil : "JSON parse error: #{raw_text.first(500)}"
    )
    Result.new(proposal: proposal, error: nil)
  rescue => e
    Rails.logger.error("[FolderTriageService] failed for #{@folder_path}: #{e.message}")
    Result.new(proposal: nil, error: e.message)
  end

  private

  def adapter
    @adapter ||= AiAdapter.build
  end

  def noise?(catalogued_file)
    ext = File.extname(catalogued_file.active_locations.first&.filename.to_s).downcase
    NOISE_EXTENSIONS.include?(ext)
  end

  # Noise files were never shown to the AI; record them as unassigned so the
  # review screen still accounts for every file in the folder.
  def append_noise(payload)
    return payload if @noise.empty?

    payload["unassigned_file_ids"] = (Array(payload["unassigned_file_ids"]) + @noise.map(&:id)).uniq
    payload
  end

  def relative_folder
    @folder_path.delete_prefix(NasSource.root.to_s).delete_prefix("/")
  end

  def system_prompt
    <<~PROMPT
      You are an expert archivist for the Padmakara Translation Group, a Buddhist publisher
      specializing in Tibetan Buddhism. You organise their file archive into a catalog with
      this model: a TEXT is one prayer/practice identified by its Tibetan title; it has one
      TRANSLATION per language; each translation has one or more VERSIONS (files: editions,
      formats, revisions of that translation).

      Always respond with a single valid JSON object. Never include prose outside the JSON.
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      Analyse this folder from the archive and group its files into catalog entries.

      Folder path (the path itself carries title/language/status hints — "OLD", "Travail",
      "Archives" suggest working or obsolete material):
      #{relative_folder}

      Files in this folder (id, filename, deterministic hints, and the AI analysis card).
      Hints: "stem" = filename without extension (files sharing a stem, e.g. X.docx and
      X.pdf, are the SAME version exported twice — keep them together as one version);
      "imposition" = true means the filename looks like a printing spread or an extracted
      page (e.g. "1_8", "p.31"), which is a fragment, not a standalone text.
      #{files_block}

      Existing texts already in the catalog (match against these before inventing a new text;
      the same text may already exist from another language's folder):
      #{existing_texts_block}

      Instructions:
      - Group files that are the same text in the same language into ONE group; the files
        are its versions. Different languages of the same text = separate groups that share
        the same Tibetan title (and existing_text_id if known).
      - Use the folder structure as the primary signal, the file cards as verification.
        If a file clearly does not belong with the others, put it in its own group or in
        unassigned_file_ids.
      - role per file: "version" (a usable rendition of the text), "working" (draft/work
        file of the same text), "fragment" (isolated pages of a larger document),
        "noise" (fonts, thumbnails, admin files, images without text).
      - NEVER invent or transliterate a Tibetan title. Fill title_tibetan ONLY by copying
        Tibetan script that actually appears in a file's card. If no card shows Tibetan
        script, leave title_tibetan null — a wrong Tibetan title is worse than none.
      - Files sharing a "stem" hint are one version (the same document in two formats):
        put them in the same group with the SAME version_label.
      - Files with "imposition": true are fragments unless a card proves otherwise.
      - version_label: short human label distinguishing this file (e.g. "A4", "livret v3.09",
        "scan"), else null.

      Return ONLY this JSON structure:
      {
        "groups": [
          {
            "title_tibetan": "Tibetan script title or null",
            "title_wylie": "Wylie transliteration or null",
            "title_translated": "title in the group's language or null",
            "language": "one of: Tibetan, French, English, Spanish, Portuguese, Finnish, Sanskrit, Other",
            "existing_text_id": null or the id of a matching existing text,
            "authors": [], "deities": [], "schools": [],
            "files": [ { "id": 0, "role": "version|working|fragment|noise", "version_label": null } ],
            "confidence": "low|medium|high",
            "notes": null
          }
        ],
        "unassigned_file_ids": [],
        "notes": "observations about the folder, or null"
      }
    PROMPT
  end

  def files_block
    @analysable.map { |cf|
      filename = cf.active_locations.first&.filename.to_s
      card = (cf.ai_file_card || {}).except("model_used", "raw", "notes").compact
      {
        id:         cf.id,
        filename:   filename,
        stem:       File.basename(filename, ".*"),
        imposition: filename.match?(IMPOSITION_PATTERN),
        card:       card
      }.to_json
    }.join("\n")
  end

  def existing_texts_block
    texts = Text.order(created_at: :desc).limit(MAX_EXISTING_TEXTS).map { |t|
      { id: t.id, title_tibetan: t.title_tibetan, title_wylie: t.title_wylie,
        title: t.title_phonetics }.compact.to_json
    }
    texts.empty? ? "(none yet)" : texts.join("\n")
  end

  def parse_response(raw_text)
    clean = raw_text.gsub(/```(?:json)?\n?/, "").strip
    parsed = JSON.parse(clean)
    parsed.is_a?(Hash) && parsed["groups"].is_a?(Array) ? parsed : nil
  rescue JSON::ParserError
    nil
  end
end
