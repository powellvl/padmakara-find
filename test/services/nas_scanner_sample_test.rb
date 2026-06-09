require "test_helper"

# Integration-style tests that run NasScanner against real (but small) fixture
# files in tmp/nas_fixtures/. These complement the unit tests in nas_scanner_test.rb
# (which use synthetic temp directories) by verifying behaviour with actual
# file content.
#
# Required structure (6 files, 5 unique checksums):
#   tmp/nas_fixtures/
#     riwo_sangchod_moved.pdf            ← file at root, outside a sub-folder
#     Sadhanas/Chenrezig/chenrezig_sadhana_fr.pdf
#     Sadhanas/Tara/tara_sadhana_tib.pdf
#     Texts/French/dup_b.pdf             ← identical content as dup_a.pdf
#     Texts/French/introduction.docx
#     Texts/Tibetan/dup_a.pdf            ← identical content as dup_b.pdf
#
# The full NAS sample (02-03 LIVRETS…) stays in tmp/nas_sample/ for
# manual/integration testing against the real dataset.
class NasScannerSampleTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  SAMPLE_ROOT = Rails.root.join("tmp/nas_fixtures").freeze

  setup do
    skip "tmp/nas_fixtures/ not found — run: cp -r tmp/nas_sample/{riwo_sangchod_moved.pdf,Sadhanas,Texts} tmp/nas_fixtures/" unless SAMPLE_ROOT.exist?

    # Process-based parallelisation disables automatic transaction rollback —
    # clean up scanner tables before each test to guarantee a fresh state.
    AiTriageProposal.delete_all rescue nil
    FileLocation.delete_all
    CataloguedFile.delete_all

    @scanner = NasScanner.new(root: SAMPLE_ROOT, logger: Logger.new(nil))
  end

  test "scanner finds all 6 sample files" do
    @scanner.call
    assert_equal 6, FileLocation.active.count,
      "Expected 6 FileLocation records — one per file in tmp/nas_sample/"
  end

  test "dup_a and dup_b share one CataloguedFile (deduplication)" do
    @scanner.call

    dup_a = FileLocation.find_by("path LIKE ?", "%dup_a%")
    dup_b = FileLocation.find_by("path LIKE ?", "%dup_b%")

    assert_not_nil dup_a, "dup_a.pdf must be indexed"
    assert_not_nil dup_b, "dup_b.pdf must be indexed"
    assert_equal dup_a.catalogued_file_id, dup_b.catalogued_file_id,
      "dup_a and dup_b have identical content — they must share one CataloguedFile"
  end

  test "file at root level (riwo_sangchod_moved.pdf) is indexed" do
    @scanner.call
    root_file = FileLocation.find_by("path LIKE ?", "%riwo_sangchod_moved%")
    assert_not_nil root_file, "File at the root of the sample tree must be indexed"
  end

  test "content types are assigned correctly" do
    @scanner.call

    pdf_types  = CataloguedFile.where(content_type: "application/pdf")
    docx_types = CataloguedFile.where(content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document")

    # 5 unique files are PDF (dup_a and dup_b share 1 CataloguedFile)
    assert pdf_types.any?,  "PDF files must get content_type application/pdf"
    assert docx_types.any?, "DOCX files must get content_type application/vnd…wordprocessingml…"
  end

  test "ExtractTextJob is enqueued for each new file" do
    assert_enqueued_jobs 0

    assert_difference "CataloguedFile.count", 5 do  # 5 unique checksums (dup_a == dup_b)
      @scanner.call
    end

    # One job per unique CataloguedFile (not per FileLocation)
    assert_enqueued_with(job: ExtractTextJob)
  end

  test "second scan is idempotent — no new records or jobs" do
    @scanner.call
    count_cf = CataloguedFile.count
    count_fl = FileLocation.count

    assert_no_enqueued_jobs(only: ExtractTextJob) do
      @scanner.call
    end

    assert_equal count_cf, CataloguedFile.count, "Second scan must not create new CataloguedFile records"
    assert_equal count_fl, FileLocation.count,   "Second scan must not create new FileLocation records"
  end

  test "NAS directory structure is preserved in FileLocation paths" do
    @scanner.call

    paths = FileLocation.pluck(:path)

    assert paths.any? { |p| p.include?("Sadhanas/Chenrezig") }, "Sadhana sub-folder path must be preserved"
    assert paths.any? { |p| p.include?("Sadhanas/Tara") }
    assert paths.any? { |p| p.include?("Texts/French") }
    assert paths.any? { |p| p.include?("Texts/Tibetan") }
  end
end
