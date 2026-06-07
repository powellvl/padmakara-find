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
    assert_select "h2", /Pipeline NAS/i
  end

  test "non-admin does not see pipeline block on home" do
    sign_in(@user)
    get root_path
    assert_select "h2", text: /Pipeline NAS/i, count: 0
  end

  test "non-admin does not see Add New Text button" do
    sign_in(@user)
    get root_path
    assert_select "a", text: /Add New Text/i, count: 0
  end

  test "admin sees Add New Text button" do
    sign_in(@admin)
    get root_path
    assert_select "a", text: /Add New Text/i
  end
end
