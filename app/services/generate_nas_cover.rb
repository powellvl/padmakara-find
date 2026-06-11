require "open3"

# Generates a Version's cover thumbnail from its first linked NAS PDF
# (catalogued_files), rendering page 1 with pdftoppm. Complements the legacy
# ExtractPdfCover which works from Active Storage attachments.
# The cover is a derived artifact, so storing it in Active Storage respects
# the "NAS is the single source of truth" rule.
class GenerateNasCover
  COVER_WIDTH = 600

  def initialize(version)
    @version = version
  end

  def call
    return false if @version.cover.attached?

    location = pdf_location
    return false unless location

    Dir.mktmpdir do |dir|
      prefix = File.join(dir, "cover")
      _out, _err, status = Open3.capture3(
        "pdftoppm", "-jpeg", "-r", "150", "-scale-to-x", COVER_WIDTH.to_s, "-scale-to-y", "-1",
        "-f", "1", "-l", "1", location.path, prefix
      )
      jpg = Dir.glob("#{prefix}*.jpg").first
      return false unless status.success? && jpg

      @version.cover.attach(
        io:           File.open(jpg),
        filename:     "cover-version-#{@version.id}.jpg",
        content_type: "image/jpeg"
      )
      true
    end
  rescue => e
    Rails.logger.error("[GenerateNasCover] failed for Version #{@version.id}: #{e.message}")
    false
  end

  private

  def pdf_location
    @version.catalogued_files.flat_map { |cf| cf.active_locations.to_a }
            .find { |loc| loc.extension == ".pdf" && File.file?(loc.path) }
  end
end
