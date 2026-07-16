require "test_helper"

class FolderTriageControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :admin)
    sign_in(@user)

    @cf = create(:catalogued_file, extraction_status: :extracted, triage_state: :pending)
    create(:file_location, catalogued_file: @cf, path: "/nas/prayers/Tara/short_praise.pdf")

    @proposal = FolderTriageProposal.create!(
      folder_path: "prayers/Tara",
      status:      :proposed,
      payload: {
        "groups" => [ {
          "title_tibetan" => "སྒྲོལ་མ།", "title_translated" => "Short praise to Tara",
          "language" => "English", "deities" => [ "Tara" ],
          "files" => [ { "id" => @cf.id, "role" => "version", "version_label" => "A4" } ],
          "confidence" => "high"
        } ],
        "unassigned_file_ids" => []
      }
    )
  end

  test "index lists proposals awaiting review" do
    get folder_triage_index_path
    assert_response :success
    assert_select "body", /prayers\/Tara/
  end

  test "show renders the proposal detail" do
    get folder_triage_path(@proposal)
    assert_response :success
    assert_select "body", /Short praise to Tara/
  end

  test "accept catalogues the folder and links files" do
    assert_difference -> { Text.count } => 1, -> { Version.count } => 1 do
      post accept_folder_triage_path(@proposal)
    end
    assert_redirected_to folder_triage_index_path
    assert @proposal.reload.applied?
    assert @cf.reload.triaged?
  end

  test "reject marks the proposal rejected without cataloguing" do
    assert_no_difference -> { Text.count } do
      post reject_folder_triage_path(@proposal)
    end
    assert @proposal.reload.rejected?
  end

  test "preview returns 404 when the file has no renderable PDF" do
    get preview_folder_triage_index_path(id: @cf)
    assert_response :not_found
  end

  test "non-admin is redirected" do
    sign_in(create(:user))
    get folder_triage_index_path
    assert_redirected_to root_path
  end
end
