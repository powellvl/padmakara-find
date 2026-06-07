require "test_helper"

class InventoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :admin)
    sign_in(@user)
  end

  test "index renders successfully with empty inventory" do
    get inventory_path
    assert_response :success
    assert_select "h1", /Inventaire NAS/i
  end

  test "index shows correct counts" do
    cf1 = create(:catalogued_file, byte_size: 1_000, content_type: "application/pdf")
    cf2 = create(:catalogued_file, byte_size: 2_000, content_type: "application/pdf")
    create(:file_location, catalogued_file: cf1)
    create(:file_location, catalogued_file: cf2)

    get inventory_path
    assert_response :success
    assert_select "p.text-2xl", /2/
  end

  test "index lists exact duplicates" do
    cf = create(:catalogued_file)
    create(:file_location, catalogued_file: cf, path: "/nas/copy_a.pdf")
    create(:file_location, catalogued_file: cf, path: "/nas/copy_b.pdf")

    get inventory_path
    assert_response :success
    assert_match "/nas/copy_a.pdf", response.body
    assert_match "/nas/copy_b.pdf", response.body
  end

  test "trigger_scan enqueues NasScanJob" do
    assert_enqueued_with(job: NasScanJob) do
      post trigger_scan_inventory_path
    end
    assert_redirected_to inventory_path
  end

  test "unauthenticated request is redirected" do
    # Make a fresh, cookie-free request without going through setup's sign_in.
    get inventory_url, headers: { "Cookie" => "" }
    assert_redirected_to new_session_path
  end
end
