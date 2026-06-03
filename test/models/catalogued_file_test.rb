require "test_helper"

class CataloguedFileTest < ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  test "valid factory" do
    cf = build(:catalogued_file)
    assert cf.valid?
  end

  test "sha256_checksum must be unique" do
    checksum = Digest::SHA256.hexdigest("content")
    create(:catalogued_file, sha256_checksum: checksum)
    dup = build(:catalogued_file, sha256_checksum: checksum)
    assert_not dup.valid?
    assert_includes dup.errors[:sha256_checksum], "has already been taken"
  end

  test "sha256_checksum must be a 64-char hex string" do
    cf = build(:catalogued_file, sha256_checksum: "not-a-hash")
    assert_not cf.valid?
  end

  test "duplicate? returns true when multiple active locations exist" do
    cf = create(:catalogued_file)
    create(:file_location, catalogued_file: cf, path: "/a.pdf")
    create(:file_location, catalogued_file: cf, path: "/b.pdf")
    assert cf.duplicate?
  end

  test "duplicate? returns false with one active location" do
    cf = create(:catalogued_file)
    create(:file_location, catalogued_file: cf)
    assert_not cf.duplicate?
  end

  test "with_multiple_active_locations scope returns only duplicates" do
    unique = create(:catalogued_file)
    create(:file_location, catalogued_file: unique)

    dup = create(:catalogued_file)
    create(:file_location, catalogued_file: dup, path: "/x.pdf")
    create(:file_location, catalogued_file: dup, path: "/y.pdf")

    result = CataloguedFile.with_multiple_active_locations
    assert_includes result, dup
    assert_not_includes result, unique
  end
end
