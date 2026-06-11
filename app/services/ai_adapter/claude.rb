module AiAdapter
  class Claude
    MODELS = {
      fast:   "claude-haiku-4-5-20251001",
      strong: "claude-opus-4-8",
      vision: "claude-haiku-4-5-20251001"
    }.freeze

    def messages(model_tier: :fast, max_tokens:, system:, messages:)
      model = MODELS.fetch(model_tier) { raise ArgumentError, "Unknown model_tier: #{model_tier}" }

      raw = anthropic_client.messages(
        model:      model,
        max_tokens: max_tokens,
        system:     system,
        messages:   messages.map { |m| { role: m[:role], content: convert_content(m[:content]) } }
      )

      Response.new(raw.content.first.text, model_used: model)
    end

    private

    def convert_content(content)
      return content if content.is_a?(String)

      content.map do |part|
        case part
        when String
          { type: "text", text: part }
        when ImagePart
          { type: "image", source: { type: "base64", media_type: part.media_type, data: part.data } }
        else
          raise ArgumentError, "Unsupported content part: #{part.class}"
        end
      end
    end

    def anthropic_client
      Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
    end
  end
end
