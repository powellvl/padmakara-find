require "pdf-reader"
require "open3"

class TextExtractor
  # Extracts plain text from a PDF.
  #
  # Strategy:
  #   1. Try pdf-reader (pure Ruby, fast, handles most PDFs).
  #   2. If pdf-reader raises or returns empty text, fall back to pdftotext
  #      (poppler CLI — handles encrypted/malformed PDFs better).
  class Pdf
    PDFTOTEXT_BIN = "pdftotext"

    def initialize(path)
      @path = path
    end

    def call
      text = extract_with_pdf_reader
      return text if text.present?

      extract_with_pdftotext
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
      Rails.logger.warn("[TextExtractor::Pdf] pdf-reader failed on #{@path}: #{e.message} — trying pdftotext")
      extract_with_pdftotext
    end

    private

    def extract_with_pdf_reader
      reader = PDF::Reader.new(@path)
      reader.pages.map { |page|
        page.text.gsub(/[[:space:]]+/, " ").strip
      }.reject(&:empty?).join("\n")
    rescue => e
      Rails.logger.warn("[TextExtractor::Pdf] pdf-reader error on #{@path}: #{e.message}")
      nil
    end

    def extract_with_pdftotext
      stdout, _stderr, status = Open3.capture3(PDFTOTEXT_BIN, "-layout", "-enc", "UTF-8", @path, "-")
      raise "pdftotext failed (exit #{status.exitstatus})" unless status.success?

      stdout.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
            .gsub(/[[:space:]]+/, " ").strip
    end
  end
end
