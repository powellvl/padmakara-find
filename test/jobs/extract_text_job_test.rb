require "test_helper"

class ExtractTextJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @cf = create(:catalogued_file,
      content_type:      "application/pdf",
      extraction_status: :pending_extraction)
    @location = create(:file_location,
      catalogued_file: @cf,
      path: Rails.root.join("test/fixtures/files/sample_text.pdf").to_s)
  end

  test "sets status to extracted and populates extracted_text" do
    ExtractTextJob.perform_now(@cf.id)
    @cf.reload
    assert_equal "extracted", @cf.extraction_status
    assert @cf.extracted_text.present?
    assert_includes @cf.extracted_text, "Padmakara"
  end

  test "updates the tsvector after extraction" do
    ExtractTextJob.perform_now(@cf.id)
    @cf.reload
    result = CataloguedFile.where(id: @cf.id)
                           .where("content_tsvector IS NOT NULL")
                           .exists?
    assert result, "content_tsvector should be populated after extraction"
  end

  test "marks unsupported_format for an InDesign file" do
    cf = create(:catalogued_file, content_type: "application/x-indesign",
                extraction_status: :pending_extraction)
    create(:file_location, catalogued_file: cf)
    ExtractTextJob.perform_now(cf.id)
    assert_equal "unsupported_format", cf.reload.extraction_status
  end

  test "marks extraction_failed when file is missing on disk" do
    @location.update!(path: "/nonexistent/ghost.pdf")
    ExtractTextJob.perform_now(@cf.id)
    assert_equal "extraction_failed", @cf.reload.extraction_status
  end

  test "is a no-op for an unknown id" do
    assert_nothing_raised { ExtractTextJob.perform_now(999_999) }
  end
end
