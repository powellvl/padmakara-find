require "application_system_test_case"

class DeitiesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    sign_in_as(@user)
    @deity = create(:deity)
  end

  test "visiting the index" do
    visit deities_url
    assert_selector "h1", text: "Deities"
  end

  test "should create deity" do
    visit deities_url
    click_on "New deity"

    fill_in "Name english", with: @deity.name_english
    fill_in "Name sanskrit", with: @deity.name_sanskrit
    fill_in "Name tibetan", with: @deity.name_tibetan
    click_on "Create Deity"

    assert_text "Deity was successfully created"
    click_on "Back"
  end

  test "should update Deity" do
    visit deity_url(@deity)
    click_on "Edit this deity", match: :first

    fill_in "Name english", with: @deity.name_english
    fill_in "Name sanskrit", with: @deity.name_sanskrit
    fill_in "Name tibetan", with: @deity.name_tibetan
    click_on "Update Deity"

    assert_text "Deity was successfully updated"
    click_on "Back"
  end

  test "should destroy Deity" do
    visit deity_url(@deity)
    click_on "Destroy this deity", match: :first

    assert_text "Deity was successfully destroyed"
  end
end
