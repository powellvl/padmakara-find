require "test_helper"

class FileLocationTest < ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  test "valid factory" do
    loc = build(:file_location)
    assert loc.valid?
  end

  test "path must be unique" do
    create(:file_location, path: "/nas/dup.pdf")
    dup = build(:file_location, path: "/nas/dup.pdf")
    assert_not dup.valid?
  end

  test "active scope excludes missing locations" do
    active  = create(:file_location)
    missing = create(:file_location, :missing)
    assert_includes FileLocation.active, active
    assert_not_includes FileLocation.active, missing
  end

  test "missing scope excludes active locations" do
    active  = create(:file_location)
    missing = create(:file_location, :missing)
    assert_includes FileLocation.missing, missing
    assert_not_includes FileLocation.missing, active
  end

  test "active? returns false when missing_since is set" do
    loc = build(:file_location, :missing)
    assert_not loc.active?
  end
end
