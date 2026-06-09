class TextExtractor
  # Extracts text from plain-text files (.txt, etc.).
  # Forces UTF-8 encoding; invalid byte sequences are replaced.
  class PlainText
    def initialize(path)
      @path = path
    end

    def call
      raw = File.read(@path, encoding: "binary")
      raw.encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: "?")
        .gsub(/[[:space:]]+/, " ").strip
    end
  end
end
