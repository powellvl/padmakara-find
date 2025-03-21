require "application_system_test_case"

class TranslationsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    sign_in_as(@user)
  end

  test "visiting the index" do
    text = create(:text)
    create(:translation, text: text, language: create(:language, :english))
    create(:translation, text: text, language: create(:language, :french))

    visit text_translations_url(text)

    assert_text "English"
    assert_text "French"
  end

  test "should create translation" do
    visit translations_url
    click_on "New translation"

    fill_in "Language", with: @translation.language
    fill_in "Text", with: @translation.text_id
    click_on "Create Translation"

    assert_text "Translation was successfully created"
    click_on "Back"
  end

  test "should update Translation" do
    visit translation_url(@translation)
    click_on "Edit this translation", match: :first

    fill_in "Language", with: @translation.language
    fill_in "Text", with: @translation.text_id
    click_on "Update Translation"

    assert_text "Translation was successfully updated"
    click_on "Back"
  end

  test "should destroy Translation" do
    visit translation_url(@translation)
    click_on "Destroy this translation", match: :first

    assert_text "Translation was successfully destroyed"
  end
end
