require "test_helper"

class DefineVersionFileAsPrimaryTest < ActiveSupport::TestCase
  test "it works" do
    version = create(:version, :with_files, files_count: 2)
    file = version.files.first
    other_file = version.files.last
    DefineVersionFileAsPrimary.new(version, file).call
    assert file.primary?
    assert_not other_file.primary?
  end
end
