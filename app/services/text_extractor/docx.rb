require "zip"
require "nokogiri"

class TextExtractor
  # Extracts plain text from a .docx (or .doc saved as docx) by reading the
  # main document XML inside the ZIP archive and collecting all <w:t> text nodes.
  class Docx
    DOCUMENT_XML_PATH = "word/document.xml"

    def initialize(path)
      @path = path
    end

    def call
      text_nodes = []

      Zip::File.open(@path) do |zip|
        entry = zip.find_entry(DOCUMENT_XML_PATH)
        raise "word/document.xml not found in #{@path}" unless entry

        xml = Nokogiri::XML(entry.get_input_stream.read)
        xml.remove_namespaces!
        text_nodes = xml.xpath("//t").map(&:text)
      end

      text_nodes.join(" ").gsub(/[[:space:]]+/, " ").strip
    end
  end
end
