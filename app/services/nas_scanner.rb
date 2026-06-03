require "digest"

# Walks the NAS source tree and populates CataloguedFile + FileLocation records.
#
# Design invariants:
#   - READ-ONLY: never writes, moves, or deletes anything under NasSource.root.
#   - Idempotent: safe to run multiple times; a second run produces identical state.
#   - Checksum-skipping: a file whose path, size, and mtime are unchanged is not
#     re-hashed — only last_seen_at is touched.
#   - Move-tolerant: a file moved to a new path gets an updated FileLocation row;
#     the CataloguedFile row (and its checksum) is unchanged.
#   - Disappearance detection: FileLocations not seen during a scan get
#     missing_since stamped; their CataloguedFile rows are kept forever.
class NasScanner
  CONTENT_TYPES = {
    ".pdf"  => "application/pdf",
    ".doc"  => "application/msword",
    ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".indd" => "application/x-indesign",
    ".inx"  => "application/x-indesign-interchange",
    ".qxd"  => "application/x-quarkxpress",
    ".qxp"  => "application/x-quarkxpress",
    ".jpg"  => "image/jpeg",
    ".jpeg" => "image/jpeg",
    ".png"  => "image/png",
    ".tif"  => "image/tiff",
    ".tiff" => "image/tiff",
    ".psd"  => "image/vnd.adobe.photoshop",
    ".ai"   => "application/postscript",
    ".eps"  => "application/postscript",
    ".txt"  => "text/plain",
    ".rtf"  => "application/rtf"
  }.freeze

  # Dotfiles, OS metadata, and working-directory cruft to ignore.
  IGNORED_NAMES = %w[.DS_Store .localized Thumbs.db desktop.ini].freeze

  def initialize(root: NasSource.root, logger: Rails.logger)
    @root   = Pathname.new(root)
    @logger = logger
  end

  def call
    unless @root.exist? && @root.directory?
      @logger.warn("[NasScanner] source root not found or not a directory: #{@root}")
      return
    end

    scan_start = Time.current
    @logger.info("[NasScanner] starting scan of #{@root}")

    walk(@root, scan_start)
    mark_missing(scan_start)

    @logger.info("[NasScanner] scan complete")
  end

  private

  def walk(dir, scan_start)
    dir.each_child do |entry|
      next if IGNORED_NAMES.include?(entry.basename.to_s)
      next if entry.basename.to_s.start_with?(".")

      if entry.directory?
        walk(entry, scan_start)
      elsif entry.file?
        process_file(entry, scan_start)
      end
    rescue => e
      @logger.error("[NasScanner] error processing #{entry}: #{e.message}")
    end
  rescue => e
    @logger.error("[NasScanner] error walking #{dir}: #{e.message}")
  end

  def process_file(path, scan_start)
    stat     = path.stat
    path_str = path.to_s

    location = FileLocation.find_by(path: path_str)

    if stable?(location, stat)
      location.update!(last_seen_at: scan_start, missing_since: nil)
      return
    end

    checksum     = Digest::SHA256.file(path_str).hexdigest
    content_type = content_type_for(path)

    catalogued = CataloguedFile.find_or_initialize_by(sha256_checksum: checksum)
    catalogued.assign_attributes(
      byte_size:     stat.size,
      content_type:  content_type,
      first_seen_at: catalogued.first_seen_at || scan_start,
      last_scan_at:  scan_start
    )
    catalogued.save!

    if location
      location.update!(
        catalogued_file: catalogued,
        mtime:           stat.mtime,
        last_seen_at:    scan_start,
        missing_since:   nil
      )
    else
      FileLocation.create!(
        catalogued_file: catalogued,
        path:            path_str,
        mtime:           stat.mtime,
        last_seen_at:    scan_start
      )
    end
  end

  # Returns true when the location record already describes this exact file,
  # meaning we can skip expensive SHA-256 I/O.
  def stable?(location, stat)
    return false unless location
    return false if location.missing_since.present?

    location.mtime.to_i == stat.mtime.to_i &&
      location.catalogued_file.byte_size == stat.size
  end

  def mark_missing(scan_start)
    FileLocation
      .active
      .where("last_seen_at < ?", scan_start)
      .update_all(missing_since: scan_start)
  end

  def content_type_for(path)
    ext = File.extname(path.to_s).downcase
    CONTENT_TYPES.fetch(ext, "application/octet-stream")
  end
end
