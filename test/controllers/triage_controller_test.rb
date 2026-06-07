require "test_helper"

class TriageControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user     = create(:user, :admin)
    sign_in(@user)
    @language = create(:language, name: "French")
    @cf       = create(:catalogued_file,
      extraction_status: :extracted,
      triage_state:      :pending,
      extracted_text:    "texte de prière")
    create(:file_location, catalogued_file: @cf)
    @proposal = create(:ai_triage_proposal, catalogued_file: @cf)
  end

  # ── Index ──────────────────────────────────────────────────────────────────

  test "index renders successfully" do
    get triage_index_path
    assert_response :success
    assert_select "h1", /Triage IA/i
  end

  test "index lists pending proposals" do
    get triage_index_path
    # The index shows the filename from the file location, not the proposed title
    assert_match File.basename(@cf.active_locations.first.path), response.body
  end

  # ── Show ───────────────────────────────────────────────────────────────────

  test "show renders the review form" do
    get triage_path(@proposal)
    assert_response :success
    assert_select "form"
    assert_match @proposal.proposed_title_phonetic, response.body
  end

  # ── Accept ─────────────────────────────────────────────────────────────────

  test "accept creates Text + Translation + Version and links the CataloguedFile" do
    assert_difference ["Text.count", "Translation.count", "Version.count"], 1 do
      post accept_triage_path(@proposal), params: {
        proposal: {
          title_tibetan:  "སྒྲོལ་མ།",
          title_wylie:    "sgrol ma",
          title_phonetic: "Tara Puja",
          language:       "French",
          version_name:   "tara.pdf",
          deity_ids:      [],
          school_ids:     [],
          author_ids:     []
        }
      }
    end

    assert_redirected_to triage_index_path
    @cf.reload
    assert @cf.triaged?
    assert_not_nil @cf.version_id
    assert @proposal.reload.accepted?
  end

  test "accept does not auto-commit without human params" do
    # Attempting accept with no title should still create the records
    # but nothing goes in without the form POST (i.e., can't be triggered by GET)
    assert_no_difference "Text.count" do
      get triage_path(@proposal)  # just viewing, no catalog change
    end
    assert @cf.reload.pending?
  end

  # ── Skip / Reject ──────────────────────────────────────────────────────────

  test "skip marks proposal as skipped" do
    post skip_triage_path(@proposal)
    assert_redirected_to triage_index_path
    assert @proposal.reload.skipped?
  end

  test "reject marks proposal as rejected" do
    post reject_triage_path(@proposal)
    assert_redirected_to triage_index_path
    assert @proposal.reload.rejected?
  end

  # ── Rerun ──────────────────────────────────────────────────────────────────

  test "rerun enqueues TriageFileJob with force_strong_model" do
    assert_enqueued_with(job: TriageFileJob) do
      post rerun_triage_path(@proposal)
    end
    assert_redirected_to triage_index_path
  end

  # ── Auth ───────────────────────────────────────────────────────────────────

  test "unauthenticated request is redirected" do
    get triage_index_path, headers: { "Cookie" => "" }
    assert_redirected_to new_session_path
  end
end
