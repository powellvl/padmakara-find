require "test_helper"

class DeitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @deity = deities(:one)
  end

  test "should get index" do
    get deities_url
    assert_response :success
  end

  test "should get new" do
    get new_deity_url
    assert_response :success
  end

  test "should create deity" do
    assert_difference("Deity.count") do
      post deities_url, params: { deity: { name_english: @deity.name_english, name_sanskrit: @deity.name_sanskrit, name_tibetan: @deity.name_tibetan } }
    end

    assert_redirected_to deity_url(Deity.last)
  end

  test "should show deity" do
    get deity_url(@deity)
    assert_response :success
  end

  test "should get edit" do
    get edit_deity_url(@deity)
    assert_response :success
  end

  test "should update deity" do
    patch deity_url(@deity), params: { deity: { name_english: @deity.name_english, name_sanskrit: @deity.name_sanskrit, name_tibetan: @deity.name_tibetan } }
    assert_redirected_to deity_url(@deity)
  end

  test "should destroy deity" do
    assert_difference("Deity.count", -1) do
      delete deity_url(@deity)
    end

    assert_redirected_to deities_url
  end
end
