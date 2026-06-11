require "json"
require "base64"

# Independent visual check before merging two Texts: compares one
# representative first page of each (the generated version covers, or a page
# rendered from a linked NAS PDF) and asks the vision model whether they are
# the same work (editions or translations of one another).
#
# Exists because text-only merge proposals over-merge thematically related
# prayers; the covers carry the ground truth (title in both scripts, artwork).
class MergeVerificationService
  Result = Data.define(:verdict, :reason) # verdict: :same | :different | :unknown

  def initialize(text_a, text_b, adapter: nil)
    @a = text_a
    @b = text_b
    @adapter = adapter
  end

  def call
    img_a = representative_image(@a)
    img_b = representative_image(@b)
    return Result.new(verdict: :unknown, reason: "missing page image") unless img_a && img_b

    response = adapter.messages(
      model_tier: :vision,
      max_tokens: 512,
      system:     system_prompt,
      messages:   [ { role: "user", content: [ prompt, img_a, img_b ] } ]
    )

    parsed = parse(response.content.first.text)
    return Result.new(verdict: :unknown, reason: "unparseable response") unless parsed

    verdict = parsed["same_work"] == true && parsed["confidence"] != "low" ? :same : :different
    Result.new(verdict: verdict, reason: parsed["reason"])
  rescue => e
    Rails.logger.error("[MergeVerification] #{@a.id} vs #{@b.id}: #{e.message}")
    Result.new(verdict: :unknown, reason: e.message)
  end

  private

  def adapter
    @adapter ||= AiAdapter.build
  end

  # Cover attachment if present (already a rendered first page), else first
  # page of a linked NAS PDF.
  def representative_image(text)
    text.translations.each do |tr|
      tr.versions.each do |v|
        if v.cover.attached?
          return AiAdapter::ImagePart.new(
            media_type: v.cover.content_type,
            data:       Base64.strict_encode64(v.cover.download)
          )
        end
      end
    end

    location = text.translations.flat_map { |tr| tr.versions }
                   .flat_map(&:catalogued_files)
                   .flat_map { |cf| cf.active_locations.to_a }
                   .find { |loc| loc.extension == ".pdf" && File.file?(loc.path) }
    return nil unless location

    PdfPageRenderer.new(location.path).cover_and_last.first
  end

  def system_prompt
    <<~PROMPT
      You are an expert archivist for a Tibetan Buddhist publisher. You compare documents
      visually. You read Tibetan script, French, English, Spanish and Portuguese.
      Always respond with a single valid JSON object, no prose outside it.
    PROMPT
  end

  def prompt
    <<~PROMPT
      Here are the first pages of two documents from the archive. Decide whether they are
      the SAME WORK — i.e. two editions of the same text, or translations of one another
      (e.g. the French and English editions of the same prayer booklet, often with the
      same layout and artwork).

      Different prayers addressed to the same deity, or different texts compiled in
      similar booklets, are NOT the same work. Compare the titles (in every script shown)
      and the content visible on the pages.

      Return ONLY:
      { "same_work": true or false, "confidence": "low|medium|high", "reason": "one short sentence" }
    PROMPT
  end

  def parse(raw)
    JSON.parse(raw.gsub(/```(?:json)?\n?/, "").strip)
  rescue JSON::ParserError
    nil
  end
end
