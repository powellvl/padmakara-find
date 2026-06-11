require "open3"
require "base64"

# Renders selected pages of a PDF to PNG images for AI vision extraction.
# Uses poppler (pdftoppm / pdfinfo), required on the host.
#
#   PdfPageRenderer.new("/path/to/file.pdf").cover_and_last
#   # => [AiAdapter::ImagePart, ...]  (1 image if single page, else first + last)
class PdfPageRenderer
  # Long edge of the rendered image. ~1500px keeps Tibetan script legible
  # for vision models while staying within typical image-size limits.
  SCALE_TO = 1536

  class RenderError < StandardError; end

  def initialize(pdf_path)
    @pdf_path = pdf_path
  end

  def page_count
    @page_count ||= begin
      out, _err, status = Open3.capture3("pdfinfo", @pdf_path)
      raise RenderError, "pdfinfo failed for #{@pdf_path}" unless status.success?

      out[/^Pages:\s+(\d+)/, 1].to_i
    end
  end

  def cover_and_last
    pages = page_count > 1 ? [ 1, page_count ] : [ 1 ]
    pages.map { |n| render_page(n) }
  end

  private

  def render_page(number)
    Dir.mktmpdir do |dir|
      prefix = File.join(dir, "page")
      _out, err, status = Open3.capture3(
        "pdftoppm", "-png", "-scale-to", SCALE_TO.to_s,
        "-f", number.to_s, "-l", number.to_s,
        @pdf_path, prefix
      )
      raise RenderError, "pdftoppm failed for #{@pdf_path} p#{number}: #{err.lines.first}" unless status.success?

      png = Dir.glob("#{prefix}*.png").first
      raise RenderError, "pdftoppm produced no output for #{@pdf_path} p#{number}" unless png

      AiAdapter::ImagePart.new(media_type: "image/png", data: Base64.strict_encode64(File.binread(png)))
    end
  end
end
