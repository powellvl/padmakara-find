require "test_helper"

class FolderTriageServiceTest < ActiveSupport::TestCase
  test "noise extensions are recognised" do
    %w[.ttf .otf .zip .rar .db .sty .qxd].each do |ext|
      assert_includes FolderTriageService::NOISE_EXTENSIONS, ext
    end
    assert_not_includes FolderTriageService::NOISE_EXTENSIONS, ".pdf"
    assert_not_includes FolderTriageService::NOISE_EXTENSIONS, ".docx"
  end

  test "imposition pattern flags spreads and page extracts, not normal titles" do
    assert_match FolderTriageService::IMPOSITION_PATTERN, "ENG 1_8.pdf"
    assert_match FolderTriageService::IMPOSITION_PATTERN, "correction p.31 copie.pdf"
    assert_match FolderTriageService::IMPOSITION_PATTERN, "livret page 12"
    assert_no_match FolderTriageService::IMPOSITION_PATTERN, "Courtes louanges à Tara.pdf"
    assert_no_match FolderTriageService::IMPOSITION_PATTERN, "Kater Dorsem v3.pdf"
  end

  test "a pure-noise folder yields an empty proposal without calling the AI" do
    cf = catalogued_file_with(".ttf")
    raising_adapter = Object.new
    def raising_adapter.messages(*) = raise("the AI must not be called")

    result = FolderTriageService.new("/nas/Fonts", [ cf ], adapter: raising_adapter).call

    assert_nil result.error
    assert result.proposal.proposed?
    assert_empty result.proposal.groups
    assert_equal [ cf.id ], result.proposal.payload["unassigned_file_ids"]
  end

  private

  def catalogued_file_with(extension)
    cf = CataloguedFile.create!(
      sha256_checksum: SecureRandom.hex(32), byte_size: 10, content_type: "application/octet-stream",
      first_seen_at: Time.current, last_scan_at: Time.current, extraction_status: :unsupported_format
    )
    cf.file_locations.create!(
      path: "/nas/Fonts/decorative#{extension}", mtime: Time.current, last_seen_at: Time.current
    )
    cf
  end
end
