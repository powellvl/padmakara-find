require "test_helper"

class NasScannerTest < ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  # Build a temporary directory that mimics a NAS subtree.
  setup do
    @tmpdir = Dir.mktmpdir("nas_scanner_test")
    @root   = Pathname.new(@tmpdir)

    # Explicit cleanup because process-based parallelisation disables
    # automatic transaction rollback between test files.
    AiTriageProposal.delete_all rescue nil
    FileLocation.delete_all
    CataloguedFile.delete_all
  end

  teardown do
    FileUtils.remove_entry(@tmpdir)
  end

  def scanner
    NasScanner.new(root: @root, logger: Logger.new(nil))
  end

  # ── Helpers ────────────────────────────────────────────────────────────────

  def write_file(relative_path, content = "hello world")
    full = @root.join(relative_path)
    full.dirname.mkpath
    full.write(content)
    full
  end

  def sha256(content)
    Digest::SHA256.hexdigest(content)
  end

  # ── Tests ──────────────────────────────────────────────────────────────────

  test "scan populates CataloguedFile and FileLocation" do
    write_file("prayers/a.pdf", "PDF content alpha")
    write_file("prayers/b.pdf", "PDF content beta")

    scanner.call

    assert_equal 2, CataloguedFile.count
    assert_equal 2, FileLocation.active.count
  end

  test "each file gets the correct checksum" do
    content = "specific content"
    write_file("doc.pdf", content)

    scanner.call

    cf = CataloguedFile.first
    assert_equal sha256(content), cf.sha256_checksum
  end

  test "re-scanning after a move does not duplicate the content record" do
    content = "prayer text"
    original = write_file("original.pdf", content)

    scanner.call
    assert_equal 1, CataloguedFile.count
    assert_equal 1, FileLocation.active.count
    content_id = CataloguedFile.first.id

    # Move the file to a new path
    moved = @root.join("moved.pdf")
    FileUtils.mv(original.to_s, moved.to_s)

    scanner.call

    # Still one unique content record
    assert_equal 1, CataloguedFile.count, "CataloguedFile must not be duplicated after a move"
    assert_equal content_id, CataloguedFile.first.id, "CataloguedFile id must be stable"

    # Old location marked missing; new location active
    old_loc = FileLocation.find_by(path: original.to_s)
    new_loc = FileLocation.find_by(path: moved.to_s)

    assert_not_nil old_loc
    assert_not_nil old_loc.missing_since, "Old path must be marked missing"

    assert_not_nil new_loc
    assert_nil new_loc.missing_since, "New path must be active"
  end

  test "re-scanning an unchanged file does not create a duplicate FileLocation" do
    write_file("stable.pdf", "unchanged")
    scanner.call
    scanner.call

    assert_equal 1, CataloguedFile.count
    assert_equal 1, FileLocation.count
  end

  test "identical content at two paths creates one CataloguedFile with two FileLocations" do
    content = "identical content"
    write_file("copy_a.pdf", content)
    write_file("copy_b.pdf", content)

    scanner.call

    assert_equal 1, CataloguedFile.count
    assert_equal 2, FileLocation.active.count
    assert CataloguedFile.first.duplicate?
  end

  test "files disappearing between scans are marked missing" do
    path = write_file("ephemeral.pdf", "will vanish")
    scanner.call
    assert_equal 1, FileLocation.active.count

    FileUtils.rm(path.to_s)
    scanner.call

    assert_equal 0, FileLocation.active.count
    assert_equal 1, FileLocation.missing.count
    assert_equal 1, CataloguedFile.count, "CataloguedFile must be retained even when all locations are missing"
  end

  test "scanner is a no-op when root does not exist" do
    scanner = NasScanner.new(root: "/nonexistent/path/#{SecureRandom.hex}", logger: Logger.new(nil))
    assert_nothing_raised { scanner.call }
    assert_equal 0, CataloguedFile.count
  end

  test "dotfiles and DS_Store are ignored" do
    write_file(".hidden_file", "hidden")
    write_file(".DS_Store", "ds store data")
    write_file("visible.pdf", "visible content")

    scanner.call

    assert_equal 1, CataloguedFile.count
    assert_equal "visible.pdf", File.basename(FileLocation.first.path)
  end
end
