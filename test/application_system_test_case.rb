require "test_helper"

Capybara.register_driver :my_playwright do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: ENV["PLAYWRIGHT_BROWSER"]&.to_sym || :chromium,
    headless: (ENV["HEADLESS"] != "false"))
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :my_playwright

  def sign_in_as(user)
    session = create(:session, user: user)

    visit new_session_path

    fill_in "email", with: user.email
    fill_in "password", with: "password123"
    click_on "Sign in"

    assert_current_path root_path
  end
end
