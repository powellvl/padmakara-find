require "test_helper"

class TextsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :admin)
    sign_in(@user)
  end

  test "index renders successfully" do
    create(:text)
    get texts_path
    assert_response :success
  end

  test "index renders across page params without error" do
    create_list(:text, 3)

    get texts_path, params: { page: 1 }
    assert_response :success

    # Out-of-range and malformed pages must not 500.
    get texts_path, params: { page: 99 }
    assert_response :success

    get texts_path, params: { page: 0 }
    assert_response :success
  end
end
