require "test_helper"
require "minitest/mock"

class FolderIngestJobTest < ActiveJob::TestCase
  setup do
    @root = NasSource.root.to_s
  end

  test "skips a folder that already has a proposal" do
    FolderTriageProposal.create!(folder_path: "prayers/Tara", status: :proposed, payload: { "groups" => [] })
    file_in("prayers/Tara", carded: true)

    assert_no_difference -> { FolderTriageProposal.count } do
      FolderIngestJob.perform_now("prayers/Tara")
    end
  end

  test "does nothing when the folder has no triageable files" do
    assert_no_difference -> { FolderTriageProposal.count } do
      FolderIngestJob.perform_now("prayers/Empty")
    end
  end

  test "creates a proposal for a folder with carded files" do
    file_in("prayers/Chenrezig", carded: true)

    fake = Struct.new(:proposal, :error)
    proposal = FolderTriageProposal.create!(folder_path: "prayers/Chenrezig", status: :proposed,
                                            payload: { "groups" => [] })
    FolderTriageService.stub(:new, ->(*) { Struct.new(:call).new(fake.new(proposal, nil)) }) do
      FolderIngestJob.perform_now("prayers/Chenrezig")
    end
    assert FolderTriageProposal.exists?(folder_path: "prayers/Chenrezig")
  end

  test "a 429 from the provider re-enqueues the job for retry" do
    file_in("prayers/Vajra", carded: true)

    rate_limited = Struct.new(:proposal, :error).new(nil, "API error 429: too many requests")
    # retry_on intercepte l'exception et réenfile le job plutôt que de la propager.
    FolderTriageService.stub(:new, ->(*) { Struct.new(:call).new(rate_limited) }) do
      assert_enqueued_with(job: FolderIngestJob) do
        FolderIngestJob.perform_now("prayers/Vajra")
      end
    end
  end

  test "a transient network error also re-enqueues the job for retry" do
    file_in("prayers/Nago", carded: true)

    net_error = Struct.new(:proposal, :error).new(nil, "SSL_read: unexpected eof while reading")
    FolderTriageService.stub(:new, ->(*) { Struct.new(:call).new(net_error) }) do
      assert_enqueued_with(job: FolderIngestJob) do
        FolderIngestJob.perform_now("prayers/Nago")
      end
    end
  end

  private

  def file_in(rel_folder, carded:)
    cf = create(:catalogued_file, extraction_status: :extracted, triage_state: :pending,
                ai_file_card: (carded ? { "doc_kind" => "complete_text" } : nil),
                ai_file_card_at: (carded ? Time.current : nil))
    create(:file_location, catalogued_file: cf,
           path: File.join(@root, rel_folder, "file_#{cf.id}.pdf"))
    cf
  end
end
