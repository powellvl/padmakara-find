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

  Result = Data.define(:proposal, :error)

  # folder_path: absolute path of the folder; files: CataloguedFiles whose
  # active location sits directly in that folder.
  def initialize(folder_path, files, adapter: nil)
    @folder_path = folder_path
    @files       = files
    @adapter     = adapter
  end

  def call
    response = adapter.messages(
      model_tier: :fast,
      max_tokens: 4096,
      system:     system_prompt,
      messages:   [ { role: "user", content: user_prompt } ]
    )

    raw_text = response.content.first.text
    payload  = parse_response(raw_text)

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

      Files in this folder (id, filename, and the AI analysis card of each file):
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
      - Do NOT invent Tibetan titles. Only fill title_tibetan when a card shows it or you
        are confident from the well-known text identity.
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
    @files.map { |cf|
      card = (cf.ai_file_card || {}).except("model_used", "raw", "notes").compact
      { id: cf.id, filename: cf.active_locations.first&.filename, card: card }.to_json
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
