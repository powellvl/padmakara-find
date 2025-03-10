require "application_system_test_case"

class TextsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    sign_in_as(@user)
    @text = create(:text)
  end

  test "visiting the index" do
    visit texts_url
    assert_selector "h1", text: "Texts"
  end

  test "should create text" do
    visit texts_url
    click_on "New text"

    fill_in "Notes", with: @text.notes
    fill_in "Title phonetics", with: @text.title_phonetics
    fill_in "Title tibetan", with: "༄༅། །བོད་སྐད་ཀྱི་མིང་ གསར་པ་"
    click_on "Create Text"

    assert_text "Text was successfully created"
    click_on "Back"
  end

  test "should update Text" do
    visit text_url(@text)
    click_on "Edit this text", match: :first

    fill_in "Notes", with: @text.notes
    fill_in "Title phonetics", with: @text.title_phonetics
    fill_in "Title tibetan", with: @text.title_tibetan
    click_on "Update Text"

    assert_text "Text was successfully updated"
    click_on "Back"
  end

  test "should destroy Text" do
    visit text_url(@text)
    click_on "Destroy this text", match: :first

    assert_text "Text was successfully destroyed"
  end
end
