require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "signing in with correct credentials" do
    user = create(:user, email: "test@example.com", password: "password123", password_confirmation: "password123")

    visit new_session_path

    fill_in "email", with: "test@example.com"
    fill_in "password", with: "password123"
    click_on "Sign in"

    assert_current_path root_path
  end

  test "signing in with incorrect credentials" do
    visit new_session_path

    fill_in "email", with: "wrong@example.com"
    fill_in "password", with: "wrongpassword"
    click_on "Sign in"

    assert_text "Try another email or password."
    assert_current_path new_session_path
  end

  test "signing out" do
    user = create(:user)
    sign_in_as(user)

    visit root_path

    find("#user-menu-button").click

    within("#user-menu") do
      click_button "Sign out"
    end

    assert_current_path new_session_path
  end
end
