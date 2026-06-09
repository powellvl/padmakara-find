require "test_helper"

class AiTriageServiceTest < ActiveSupport::TestCase
  setup do
    @cf = create(:catalogued_file,
      extraction_status: :extracted,
      extracted_text: "Om Tara Tuttare Ture Soha. This is a sadhana of Green Tara.")
    create(:file_location, catalogued_file: @cf, path: "/nas/tara_sadhana.pdf")
  end

  def stub_response_json(overrides = {})
    {
      "is_prayer_text"  => true,
      "language"        => "English",
      "title_tibetan"   => nil,
      "title_wylie"     => nil,
      "title_phonetic"  => "Tara Sadhana",
      "deities"         => [ "Tara" ],
      "schools"         => [ "Nyingma" ],
      "authors"         => [],
      "confidence"      => "high",
      "notes"           => "Green Tara practice text"
    }.merge(overrides).to_json
  end

  # Builds a fake adapter that returns a proper AiAdapter::Response.
  # Accepts any keyword args so it works regardless of model_tier passed.
  def build_fake_adapter(raw_json, model_used: "test-model-fast")
    response = AiAdapter::Response.new(raw_json, model_used: model_used)
    Class.new { define_method(:messages) { |**_| response } }.new
  end

  test "creates an AiTriageProposal with a stubbed adapter response" do
    fake = build_fake_adapter(stub_response_json)
    result = AiTriageService.new(@cf, adapter: fake).call

    assert_nil result.error
    assert_not_nil result.proposal
    assert_equal "Tara Sadhana", result.proposal.proposed_title_phonetic
    assert_equal [ "Tara" ], result.proposal.proposed_deity_names
    assert_equal "high", result.proposal.confidence
    assert_equal "test-model-fast", result.proposal.model_used
  end

  test "model_used reflects the adapter's resolved model" do
    fake = build_fake_adapter(stub_response_json, model_used: "mistral-small-latest")
    result = AiTriageService.new(@cf, adapter: fake).call

    assert_equal "mistral-small-latest", result.proposal.model_used
  end

  test "force_strong_model passes :strong tier to the adapter" do
    received_tier = nil
    adapter = Class.new do
      define_method(:messages) do |model_tier:, **_|
        received_tier = model_tier
        AiAdapter::Response.new("{}", model_used: "strong-model")
      end
    end.new

    AiTriageService.new(@cf, force_strong_model: true, adapter: adapter).call

    assert_equal :strong, received_tier
  end

  test "default call passes :fast tier to the adapter" do
    received_tier = nil
    adapter = Class.new do
      define_method(:messages) do |model_tier:, **_|
        received_tier = model_tier
        AiAdapter::Response.new("{}", model_used: "fast-model")
      end
    end.new

    AiTriageService.new(@cf, adapter: adapter).call

    assert_equal :fast, received_tier
  end

  test "returns an error result when the adapter raises" do
    raising_adapter = Object.new
    def raising_adapter.messages(**) = raise "network error"

    result = AiTriageService.new(@cf, adapter: raising_adapter).call

    assert_nil result.proposal
    assert_match "network error", result.error
  end

  test "handles malformed JSON gracefully" do
    fake   = build_fake_adapter("not json at all")
    result = AiTriageService.new(@cf, adapter: fake).call

    assert_nil result.error
    assert_equal "low", result.proposal.confidence
  end

  test "strips markdown fences from JSON response" do
    with_fences = "```json\n#{stub_response_json}\n```"
    fake   = build_fake_adapter(with_fences)
    result = AiTriageService.new(@cf, adapter: fake).call

    assert_nil result.error
    assert_equal "Tara Sadhana", result.proposal.proposed_title_phonetic
  end
end
