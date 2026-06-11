require "net/http"
require "json"

module AiAdapter
  # Adapter for any OpenAI-compatible chat completions API.
  # Covers Mistral, OpenAI, Groq — all share the same /v1/chat/completions interface.
  class OpenAiCompatible
    PROVIDERS = {
      "mistral" => {
        base_url: "https://api.mistral.ai",
        env_key:  "MISTRAL_API_KEY",
        models:   { fast: "mistral-small-latest", strong: "mistral-large-latest", vision: "mistral-small-latest" }
      },
      "openai" => {
        base_url: "https://api.openai.com",
        env_key:  "OPENAI_API_KEY",
        models:   { fast: "gpt-4o-mini", strong: "gpt-4o", vision: "gpt-4o-mini" }
      },
      "groq" => {
        base_url: "https://api.groq.com/openai",
        env_key:  "GROQ_API_KEY",
        models:   { fast: "llama-3.1-8b-instant", strong: "llama-3.3-70b-versatile",
                    vision: "meta-llama/llama-4-scout-17b-16e-instruct" }
      }
    }.freeze

    def messages(model_tier: :fast, max_tokens:, system:, messages:)
      provider_name = ENV.fetch("AI_PROVIDER", "mistral").downcase
      config        = PROVIDERS.fetch(provider_name) { raise ArgumentError, "Unknown provider: #{provider_name}" }
      model         = config[:models].fetch(model_tier) { raise ArgumentError, "Unknown model_tier: #{model_tier}" }
      api_key       = ENV.fetch(config[:env_key])

      # Merge system prompt as first message (OpenAI convention)
      oai_messages = [ { role: "system", content: system },
                       *messages.map { |m| { role: m[:role], content: convert_content(m[:content]) } } ]
      body = JSON.generate(model: model, max_tokens: max_tokens, messages: oai_messages)

      text = post_completion(config[:base_url], api_key, body)
      Response.new(text, model_used: model)
    end

    private

    def convert_content(content)
      return content if content.is_a?(String)

      content.map do |part|
        case part
        when String
          { type: "text", text: part }
        when ImagePart
          { type: "image_url", image_url: { url: "data:#{part.media_type};base64,#{part.data}" } }
        else
          raise ArgumentError, "Unsupported content part: #{part.class}"
        end
      end
    end

    def post_completion(base_url, api_key, body)
      uri = URI("#{base_url}/v1/chat/completions")

      # Vision payloads (base64 images) can take well over the 60s default.
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 180, write_timeout: 180) do |http|
        req = Net::HTTP::Post.new(uri)
        req["Content-Type"]  = "application/json"
        req["Authorization"] = "Bearer #{api_key}"
        req.body = body

        resp = http.request(req)
        raise "API error #{resp.code}: #{resp.body}" unless resp.is_a?(Net::HTTPSuccess)

        parsed = JSON.parse(resp.body)
        parsed.dig("choices", 0, "message", "content") ||
          raise("Unexpected response structure: #{resp.body}")
      end
    end
  end
end
