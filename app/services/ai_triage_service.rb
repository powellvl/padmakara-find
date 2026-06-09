require "json"

# Calls the configured AI provider to analyse a CataloguedFile's extracted text
# and return a structured triage proposal.
#
# The provider is selected via AI_PROVIDER env var (default: "claude").
# Model tier:
#   :fast   — bulk first pass  (Claude Haiku / Mistral Small / etc.)
#   :strong — low-confidence re-runs, triggered manually (Claude Opus / Mistral Large / etc.)
#
# The service NEVER writes to the catalog. It creates an AiTriageProposal record
# and returns it. A human must accept/edit the proposal to create catalog entries.
class AiTriageService
  # Maximum characters of extracted text sent to the API to control token cost.
  MAX_TEXT_CHARS = 4_000

  Result = Data.define(:proposal, :error)

  def initialize(catalogued_file, force_strong_model: false, adapter: nil)
    @cf                 = catalogued_file
    @force_strong_model = force_strong_model
    @adapter            = adapter
  end

  def call
    text_sample = (@cf.extracted_text || "").first(MAX_TEXT_CHARS)
    filename    = @cf.active_locations.first&.filename || "(unknown)"

    response = adapter.messages(
      model_tier: model_tier,
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
      model_used:              response.model_used,
      raw_response:            { text: raw_text }
    )

    Result.new(proposal: proposal, error: nil)
  rescue => e
    Rails.logger.error("[AiTriageService] failed for CataloguedFile #{@cf.id}: #{e.message}")
    Result.new(proposal: nil, error: e.message)
  end

  private

  def adapter
    @adapter ||= AiAdapter.build
  end

  def model_tier
    @force_strong_model ? :strong : :fast
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
    clean = raw_text.gsub(/```(?:json)?\n?/, "").strip
    JSON.parse(clean)
  rescue JSON::ParserError
    {
      "is_prayer_text" => nil,
      "language"       => nil,
      "confidence"     => "low",
      "notes"          => "JSON parse error — raw response saved for manual review"
    }
  end
end
