require "test_helper"

# Ensures role-based access is enforced on admin-only controllers.
class AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @user  = create(:user)
    @admin = create(:user, :admin)
  end

  # ── Inventory ────────────────────────────────────────────────────────────

  test "non-admin cannot access inventory" do
    sign_in(@user)
    get inventory_path
    assert_redirected_to root_path
  end

  test "admin can access inventory" do
    sign_in(@admin)
    get inventory_path
    assert_response :success
  end

  # ── Triage ───────────────────────────────────────────────────────────────

  test "non-admin cannot access triage index" do
    sign_in(@user)
    get triage_index_path
    assert_redirected_to root_path
  end

  test "admin can access triage index" do
    sign_in(@admin)
    get triage_index_path
    assert_response :success
  end

  # ── Home pipeline block ───────────────────────────────────────────────────

  test "admin sees pipeline block on home" do
    sign_in(@admin)
    get root_path
    assert_match "Pipeline NAS", response.body
  end

  test "non-admin does not see pipeline block on home" do
    sign_in(@user)
    get root_path
    assert_no_match "Pipeline NAS", response.body
  end

  test "non-admin does not see new text button" do
    sign_in(@user)
    get root_path
    assert_no_match "Nouveau texte", response.body
  end

  test "admin sees new text button" do
    sign_in(@admin)
    get root_path
    assert_match "Nouveau texte", response.body
  end
end
