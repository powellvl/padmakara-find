class TextExtractor
  # Extracts plain text from RTF files by stripping RTF control words and
  # special characters. This is a lightweight approach — it covers the common
  # case of RTF prayer texts without requiring an external binary.
  #
  # Note: complex RTF features (tables, embedded objects) are silently dropped.
  class Rtf
    def initialize(path)
      @path = path
    end

    def call
      raw = File.read(@path, encoding: "binary")

      # Decode RTF escaped characters (e.g. \'e9 → é) — keep as binary bytes
      text = raw.gsub(/\\'([0-9a-fA-F]{2})/) { [ $1.to_i(16) ].pack("C") }

      # Remove control groups that contain non-readable metadata
      text = text.gsub(/\{[^{}]*\}/, "")

      # Remove remaining control words and backslash sequences
      text = text.gsub(/\\[a-zA-Z]+\d*\s?/, "")
                 .gsub(/\\[^a-zA-Z]/, "")
                 .gsub(/[{}]/, "")

      text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
          .gsub(/[[:space:]]+/, " ").strip
    end
  end
end
