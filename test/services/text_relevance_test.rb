require "test_helper"

class TextRelevanceTest < ActiveSupport::TestCase
  test "archive_only? is true when every file sits under an archive folder" do
    text = text_with_files([
      "/nas/Prieres/02-03-12 Archives/Anciennes Versions/tara.pdf",
      "/nas/Prieres/Copie ancien ordi/tara old.pdf"
    ])
    assert TextRelevance.archive_only?(text)
  end

  test "archive_only? is false when at least one file is outside archives" do
    text = text_with_files([
      "/nas/Prieres/02-03-12 Archives/Anciennes Versions/tara.pdf",
      "/nas/Prieres/Sadhanas/Tara/tara.pdf"
    ])
    assert_not TextRelevance.archive_only?(text)
  end

  test "archive_only? is false for a text with no localised files" do
    text = create(:text)
    assert_not TextRelevance.archive_only?(text)
  end

  test "refresh! persists the flag" do
    text = text_with_files([ "/nas/x/OLD/a.pdf" ])
    TextRelevance.refresh!(text)
    assert text.reload.archived?
  end

  private

  def text_with_files(paths)
    text = create(:text)
    translation = create(:translation, text: text, language: create(:language))
    version = create(:version, translation: translation)
    paths.each do |path|
      cf = create(:catalogued_file, version: version, triage_state: :triaged)
      create(:file_location, catalogued_file: cf, path: path)
    end
    text
  end
end
