module AiAdapter
  class Claude
    MODELS = {
      fast:   "claude-haiku-4-5-20251001",
      strong: "claude-opus-4-8"
    }.freeze

    def messages(model_tier: :fast, max_tokens:, system:, messages:)
      model = MODELS.fetch(model_tier) { raise ArgumentError, "Unknown model_tier: #{model_tier}" }

      raw = anthropic_client.messages(
        model:      model,
        max_tokens: max_tokens,
        system:     system,
        messages:   messages
      )

      Response.new(raw.content.first.text, model_used: model)
    end

    private

    def anthropic_client
      Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
    end
  end
end
