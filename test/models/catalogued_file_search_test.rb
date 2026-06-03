require "test_helper"

# Tests for the full_text_search scope added in Phase 02.
class CataloguedFileSearchTest < ActiveSupport::TestCase
  setup do
    # A file with extracted text
    @cf_with_text = create(:catalogued_file,
      extraction_status: :extracted,
      extracted_text: "Chenrezig sadhana practice text")
    create(:file_location, catalogued_file: @cf_with_text, path: "/nas/chenrezig.pdf")
    @cf_with_text.update_tsvector!

    # A file found only by filename, no extracted text
    @cf_filename_only = create(:catalogued_file, extraction_status: :unsupported_format)
    create(:file_location, catalogued_file: @cf_filename_only, path: "/nas/tara_sadhana.pdf")

    # A file that should NOT appear
    @cf_unrelated = create(:catalogued_file, extraction_status: :extracted,
                           extracted_text: "unrelated document about something else")
    create(:file_location, catalogued_file: @cf_unrelated, path: "/nas/unrelated.pdf")
    @cf_unrelated.update_tsvector!
  end

  test "finds files by extracted text content" do
    results = CataloguedFile.full_text_search("Chenrezig")
    assert_includes results, @cf_with_text
    assert_not_includes results, @cf_unrelated
  end

  test "finds files by filename path match" do
    results = CataloguedFile.full_text_search("tara_sadhana")
    assert_includes results, @cf_filename_only
  end

  test "does not return results for missing locations" do
    @cf_with_text.active_locations.update_all(missing_since: Time.current)
    results = CataloguedFile.full_text_search("Chenrezig")
    assert_not_includes results, @cf_with_text
  end

  test "returns empty when nothing matches" do
    results = CataloguedFile.full_text_search("zzznomatch999")
    assert_empty results
  end
end
