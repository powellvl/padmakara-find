require "test_helper"
require "zip"

class TextExtractorTest < ActiveSupport::TestCase
  FIXTURES_DIR = Rails.root.join("test/fixtures/files")

  # ── Helpers ──────────────────────────────────────────────────────────────

  def real_pdf_path
    FIXTURES_DIR.join("sample_text.pdf").to_s
  end

  # Build a minimal valid docx (ZIP with word/document.xml) in a temp file.
  def build_docx(text)
    tmp = Tempfile.new([ "test", ".docx" ])
    Zip::OutputStream.open(tmp.path) do |zip|
      zip.put_next_entry("word/document.xml")
      zip.write(<<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:body>
            <w:p><w:r><w:t>#{text}</w:t></w:r></w:p>
          </w:body>
        </w:document>
      XML
    end
    tmp
  end

  # ── PDF extraction ────────────────────────────────────────────────────────

  test "extracts text from a valid PDF" do
    result = TextExtractor.new(real_pdf_path, "application/pdf").call
    assert_equal :extracted, result.status
    assert_includes result.text, "Padmakara"
  end

  test "returns extraction_failed for a corrupt PDF" do
    Tempfile.create([ "corrupt", ".pdf" ]) do |f|
      f.write("not a pdf")
      f.flush
      result = TextExtractor.new(f.path, "application/pdf").call
      assert_equal :extraction_failed, result.status
      assert_not_nil result.error
    end
  end

  # ── docx extraction ───────────────────────────────────────────────────────

  test "extracts text from a valid docx" do
    docx = build_docx("Chenrezig sadhana")
    result = TextExtractor.new(docx.path, "application/vnd.openxmlformats-officedocument.wordprocessingml.document").call
    assert_equal :extracted, result.status
    assert_includes result.text, "Chenrezig"
  ensure
    docx.close
    docx.unlink
  end

  test "returns extraction_failed for a corrupt docx" do
    Tempfile.create([ "corrupt", ".docx" ]) do |f|
      f.write("not a zip")
      f.flush
      result = TextExtractor.new(f.path, "application/vnd.openxmlformats-officedocument.wordprocessingml.document").call
      assert_equal :extraction_failed, result.status
    end
  end

  # ── Unsupported formats ───────────────────────────────────────────────────

  test "returns unsupported_format for an InDesign file" do
    result = TextExtractor.new("/some/file.indd", "application/x-indesign").call
    assert_equal :unsupported_format, result.status
    assert_nil result.text
  end

  test "returns unsupported_format for a JPEG" do
    result = TextExtractor.new("/some/file.jpg", "image/jpeg").call
    assert_equal :unsupported_format, result.status
  end

  # ── Dispatcher ────────────────────────────────────────────────────────────

  test "unknown content_type returns unsupported_format without raising" do
    result = TextExtractor.new("/some/archive.zip", "application/zip").call
    assert_equal :unsupported_format, result.status
    assert_nil result.error
  end
end
