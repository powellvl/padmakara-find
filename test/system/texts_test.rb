require "application_system_test_case"

class TextsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    sign_in_as(@user)
  end

  test "visiting the index" do
    texts = 3.times.map { create(:text) }

    visit texts_url

    texts.each do |text|
      assert_text text.title_tibetan
    end
  end

  test "should create text" do
    visit texts_url
    click_on "New text"

    fill_in "Title tibetan", with: "A unique Tibetan title"
    fill_in "Title phonetics", with: "Some phonetics"
    fill_in "Notes", with: "Some notes"
    click_on "Create Text"

    assert_current_path texts_path
    assert_text "A unique Tibetan title"
  end

  test "should update Text" do
    text = create(:text)
    visit text_translations_url(text)
    within "#text-info" do
      click_on "Edit"
    end

    fill_in "Notes", with: "Different notes"
    fill_in "Title phonetics", with: "Different phonetics"
    fill_in "Title tibetan", with: "Different Tibetan"
    click_on "Update Text"

    assert_current_path texts_path
    assert_text "Different Tibetan"
    text.reload
    assert text.title_phonetics == "Different phonetics"
    assert text.notes == "Different notes"
  end

  test "should destroy Text" do
    text = create(:text)
    visit text_translations_url(text)
    page.accept_confirm do
      click_on "Remove", match: :first
    end

    assert_text "Text was successfully destroyed"
  end
end
