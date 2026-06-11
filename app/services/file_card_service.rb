require "json"

# Builds the per-file "card": a structured AI extraction of one CataloguedFile's
# identity signals (titles, languages, Tibetan script, version hints).
#
# PDFs are analysed visually (cover + last page rendered to images) because
# Tibetan text inside PDFs is almost always mis-encoded even when it displays
# correctly — copy/extracted text is unreliable. Other formats with extracted
# text fall back to a text sample.
#
# The card is stored on catalogued_files.ai_file_card and later consumed by
# FolderTriageService. This service never writes to the catalog itself.
class FileCardService
  MAX_TEXT_CHARS = 4_000

  Result = Data.define(:card, :error)

  def initialize(catalogued_file, adapter: nil)
    @cf      = catalogued_file
    @adapter = adapter
  end

  def call
    location = @cf.active_locations.first
    return Result.new(card: nil, error: "no active location") unless location

    content = build_content(location)
    return Result.new(card: nil, error: "no analysable content") unless content

    response = adapter.messages(
      model_tier: content.any?(AiAdapter::ImagePart) ? :vision : :fast,
      max_tokens: 1024,
      system:     system_prompt,
      messages:   [ { role: "user", content: content } ]
    )

    card = parse_response(response.content.first.text)
    card["model_used"] = response.model_used
    @cf.update!(ai_file_card: card, ai_file_card_at: Time.current)
    Result.new(card: card, error: nil)
  rescue => e
    Rails.logger.error("[FileCardService] failed for CataloguedFile #{@cf.id}: #{e.message}")
    Result.new(card: nil, error: e.message)
  end

  private

  def adapter
    @adapter ||= AiAdapter.build
  end

  def build_content(location)
    if pdf?(location) && File.exist?(location.path)
      images = PdfPageRenderer.new(location.path).cover_and_last
      [ vision_prompt(location, images.size), *images ]
    elsif @cf.extracted_text.present?
      [ text_prompt(location, @cf.extracted_text.first(MAX_TEXT_CHARS)) ]
    end
  end

  def pdf?(location)
    location.path.downcase.end_with?(".pdf")
  end

  def system_prompt
    <<~PROMPT
      You are an expert archivist for the Padmakara Translation Group, a Buddhist publisher
      specializing in Tibetan Buddhism. You analyse files from their archive to extract
      identity metadata. You read Tibetan script (Uchen), Wylie transliteration, French,
      English, Spanish and Portuguese.

      Always respond with a single valid JSON object. Never include prose outside the JSON.
    PROMPT
  end

  def card_schema
    <<~SCHEMA
      {
        "doc_kind": "one of: complete_text (a full prayer/practice text), fragment (single pages or excerpt of a larger text), cover_only, administrative (invoices, emails, notes, indexes), other",
        "is_prayer_text": true or false,
        "languages": ["languages of the CONTENT, from: Tibetan, French, English, Spanish, Portuguese, Finnish, Sanskrit, Other"],
        "has_tibetan_script": true or false,
        "title_tibetan": "title in Tibetan script (Uchen) if visible/identifiable, else null",
        "title_wylie": "Wylie transliteration of the Tibetan title if identifiable, else null",
        "title_translated": "translated or phonetic title (in the document's language) if identifiable, else null",
        "authors": ["masters/authors of the text, e.g. Dudjom Rinpoche, Patrul Rinpoche"],
        "deities": ["deities/yidams the text is addressed to, e.g. Chenrezig, Tara, Vajrasattva"],
        "version_hint": "edition/format/revision info visible on the document (e.g. 'v3.09', 'A4 booklet', '2nd edition 2013'), else null",
        "confidence": "low, medium, or high",
        "notes": "short relevant observations, else null"
      }
    SCHEMA
  end

  def vision_prompt(location, image_count)
    pages = image_count > 1 ? "the cover (first page) and the last page" : "the only page"
    <<~PROMPT
      Analyse this document from the archive. You are given #{pages} as images.
      Titles, authors and edition info usually appear on these pages, often in both
      Tibetan script and a translated form.

      File path: #{relative_path(location)}

      Return ONLY this JSON structure (no markdown, no explanation):
      #{card_schema}
    PROMPT
  end

  def text_prompt(location, sample)
    <<~PROMPT
      Analyse this document from the archive, from its extracted text below.
      Note: Tibetan script may appear garbled if the source used legacy fonts —
      if you see implausible character salad where Tibetan is expected, say so in notes
      and do not invent a Tibetan title.

      File path: #{relative_path(location)}

      Extracted text (truncated to #{MAX_TEXT_CHARS} characters):
      ---
      #{sample}
      ---

      Return ONLY this JSON structure (no markdown, no explanation):
      #{card_schema}
    PROMPT
  end

  def relative_path(location)
    location.path.delete_prefix(NasSource.root.to_s).delete_prefix("/")
  end

  def parse_response(raw_text)
    clean = raw_text.gsub(/```(?:json)?\n?/, "").strip
    JSON.parse(clean)
  rescue JSON::ParserError
    { "doc_kind" => "other", "confidence" => "low",
      "notes" => "JSON parse error", "raw" => raw_text.first(2_000) }
  end
end
