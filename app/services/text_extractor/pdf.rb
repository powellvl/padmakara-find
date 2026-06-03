require "pdf-reader"

class TextExtractor
  # Extracts plain text from a PDF using the pdf-reader gem.
  # Joins all pages with a newline; strips excessive whitespace runs.
  class Pdf
    def initialize(path)
      @path = path
    end

    def call
      reader = PDF::Reader.new(@path)
      reader.pages.map { |page|
        page.text.gsub(/[[:space:]]+/, " ").strip
      }.reject(&:empty?).join("\n")
    end
  end
end
