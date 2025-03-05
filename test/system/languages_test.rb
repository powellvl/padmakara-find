require "application_system_test_case"

class LanguagesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    sign_in_as(@user)
    @language = create(:language, :english)
  end

  test "visiting the index" do
    visit languages_url
    assert_selector "h1", text: "Languages"
  end

  test "should create language" do
    visit languages_url
    click_on "New language"

    fill_in "Name", with: "Italian"
    click_on "Create Language"

    assert_text "Language was successfully created"
    click_on "Back"
  end

  test "should update Language" do
    visit language_url(@language)
    click_on "Edit this language", match: :first

    fill_in "Name", with: "Updated #{@language.name}"
    click_on "Update Language"

    assert_text "Language was successfully updated"
    click_on "Back"
  end

  test "should destroy Language" do
    # Create a language that's not associated with any translations
    language_to_destroy = create(:language, name: "Language to destroy")

    visit language_url(language_to_destroy)
    click_on "Destroy this language", match: :first

    assert_text "Language was successfully destroyed"
  end
end
