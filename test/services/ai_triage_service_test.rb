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

  # Returns a plain Ruby object that stands in for Anthropic::Client.
  # Accepts any keyword arguments (the real SDK uses kwargs for `messages`).
  def build_mock_client(raw_json)
    mock_message  = Struct.new(:text).new(raw_json)
    mock_response = Struct.new(:content).new([ mock_message ])
    Class.new { define_method(:messages) { |**_| mock_response } }.new
  end

  test "creates an AiTriageProposal with a stubbed API response" do
    mock = build_mock_client(stub_response_json)
    result = AiTriageService.new(@cf, client: mock).call

    assert_nil result.error
    assert_not_nil result.proposal
    assert_equal "Tara Sadhana", result.proposal.proposed_title_phonetic
    assert_equal [ "Tara" ], result.proposal.proposed_deity_names
    assert_equal "high", result.proposal.confidence
    assert_equal AiTriageService::HAIKU_MODEL, result.proposal.model_used
  end

  test "uses the strong model when force_strong_model is true" do
    mock   = build_mock_client(stub_response_json)
    result = AiTriageService.new(@cf, force_strong_model: true, client: mock).call

    assert_equal AiTriageService::OPUS_MODEL, result.proposal.model_used
  end

  test "returns an error result when the API raises" do
    raising_client = Object.new
    def raising_client.messages(**) = raise "network error"

    result = AiTriageService.new(@cf, client: raising_client).call

    assert_nil result.proposal
    assert_match "network error", result.error
  end

  test "handles malformed JSON gracefully" do
    mock   = build_mock_client("not json at all")
    result = AiTriageService.new(@cf, client: mock).call

    assert_nil result.error
    assert_equal "low", result.proposal.confidence
  end
end
