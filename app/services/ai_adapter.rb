# Factory and shared value objects for AI provider adapters.
#
# Usage:
#   adapter = AiAdapter.build          # reads AI_PROVIDER env var (default: "claude")
#   response = adapter.messages(
#     model_tier: :fast,               # :fast or :strong
#     max_tokens: 512,
#     system:     "...",
#     messages:   [{ role: "user", content: "..." }]
#   )
#   response.content.first.text        # extracted text
#   response.model_used                # e.g. "mistral-small-latest"
#
# Supported providers (AI_PROVIDER env):
#   "claude"  — Anthropic SDK (default, requires ANTHROPIC_API_KEY)
#   "mistral" — Mistral AI     (requires MISTRAL_API_KEY)
#   "openai"  — OpenAI         (requires OPENAI_API_KEY)
#   "groq"    — Groq           (requires GROQ_API_KEY)
module AiAdapter
  # Mimics Anthropic SDK's content block so callers use a uniform interface.
  ContentBlock = Data.define(:text)

  # Uniform image part for multimodal messages. Message content is either a
  # plain String or an Array mixing Strings and ImagePart instances; each
  # adapter converts to its provider's wire format.
  #   ImagePart.new(media_type: "image/png", data: Base64.strict_encode64(bytes))
  ImagePart = Data.define(:media_type, :data)

  # Uniform response returned by all adapters.
  class Response
    attr_reader :model_used

    def initialize(text, model_used:)
      @text       = text
      @model_used = model_used
    end

    def content
      [ ContentBlock.new(text: @text) ]
    end
  end

  def self.build
    provider = ENV.fetch("AI_PROVIDER", "claude").downcase
    case provider
    when "claude"
      require_relative "ai_adapter/claude"
      Claude.new
    when "mistral", "openai", "groq"
      require_relative "ai_adapter/open_ai_compatible"
      OpenAiCompatible.new
    else
      raise ArgumentError, "Unknown AI_PROVIDER: #{provider}. Valid: claude, mistral, openai, groq"
    end
  end
end
