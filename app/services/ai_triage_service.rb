require "json"

# Calls the Claude API to analyse a CataloguedFile's extracted text and return
# a structured triage proposal.
#
# Tiering:
#   - claude-haiku-4-5-20251001 for the bulk first pass
#   - claude-opus-4-8            for low-confidence re-runs (triggered manually)
#
# The service NEVER writes to the catalog. It creates an AiTriageProposal record
# and returns it. A human must accept/edit the proposal to create catalog entries.
class AiTriageService
  HAIKU_MODEL = "claude-haiku-4-5-20251001"
  OPUS_MODEL  = "claude-opus-4-8"

  # Maximum characters of extracted text sent to the API to control token cost.
  MAX_TEXT_CHARS = 4_000

  Result = Data.define(:proposal, :error)

  def initialize(catalogued_file, force_strong_model: false, client: nil)
    @cf                 = catalogued_file
    @force_strong_model = force_strong_model
    @client             = client
  end

  def call
    text_sample = (@cf.extracted_text || "").first(MAX_TEXT_CHARS)
    filename    = @cf.active_locations.first&.filename || "(unknown)"

    response = client.messages(
      model:      model_to_use,
      max_tokens: 512,
      system:     system_prompt,
      messages:   [ { role: "user", content: user_prompt(filename, text_sample) } ]
    )

    raw_text = response.content.first.text
    parsed   = parse_response(raw_text)

    proposal = AiTriageProposal.create!(
      catalogued_file:         @cf,
      proposed_title_tibetan:  parsed["title_tibetan"],
      proposed_title_wylie:    parsed["title_wylie"],
      proposed_title_phonetic: parsed["title_phonetic"],
      proposed_language:       parsed["language"],
      is_prayer_text:          parsed.fetch("is_prayer_text", true),
      proposed_deity_names:    Array(parsed["deities"]),
      proposed_school_names:   Array(parsed["schools"]),
      proposed_author_names:   Array(parsed["authors"]),
      confidence:              parsed["confidence"],
      ai_notes:                parsed["notes"],
      model_used:              model_to_use,
      raw_response:            { text: raw_text }
    )

    Result.new(proposal: proposal, error: nil)
  rescue => e
    Rails.logger.error("[AiTriageService] failed for CataloguedFile #{@cf.id}: #{e.message}")
    Result.new(proposal: nil, error: e.message)
  end

  private

  def client
    @client ||= Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
  end

  def model_to_use
    @force_strong_model ? OPUS_MODEL : HAIKU_MODEL
  end

  def system_prompt
    <<~PROMPT
      You are an expert assistant for the Padmakara Translation Group, a Buddhist publisher
      specializing in Tibetan Buddhism. Your task is to analyze prayer and liturgical texts
      and extract structured metadata for cataloging purposes.

      Always respond with a single valid JSON object. Never include prose outside the JSON.
    PROMPT
  end

  def user_prompt(filename, text_sample)
    <<~PROMPT
      Analyze the following file and extracted text, then return a JSON object with the
      catalog metadata.

      Filename: #{filename}

      Extracted text (truncated to #{MAX_TEXT_CHARS} characters):
      ---
      #{text_sample.presence || "(no text extracted)"}
      ---

      Return ONLY this JSON structure (no markdown, no explanation):
      {
        "is_prayer_text": true or false,
        "language": "primary language — one of: Tibetan, French, English, Sanskrit, Mixed, Unknown",
        "title_tibetan": "Tibetan script title if identifiable, else null",
        "title_wylie": "Wylie transliteration of the title if identifiable, else null",
        "title_phonetic": "phonetic/English title if identifiable, else null",
        "deities": ["list of deity or yidam names mentioned, e.g. Chenrezig, Tara, Vajrasattva"],
        "schools": ["list of Buddhist schools or lineages, e.g. Nyingma, Kagyu, Gelug"],
        "authors": ["list of masters or authors mentioned, e.g. Dudjom Rinpoche, Patrul Rinpoche"],
        "confidence": "low, medium, or high",
        "notes": "any relevant observations about the text, e.g. appears to be a sadhana, translation quality, etc."
      }
    PROMPT
  end

  def parse_response(raw_text)
    # Strip markdown fences if the model added them despite instructions
    clean = raw_text.gsub(/```(?:json)?\n?/, "").strip
    JSON.parse(clean)
  rescue JSON::ParserError
    # Return a minimal fallback so the proposal is still created
    {
      "is_prayer_text" => nil,
      "language"       => nil,
      "confidence"     => "low",
      "notes"          => "JSON parse error — raw response saved for manual review"
    }
  end
end
