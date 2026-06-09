require "open3"

class TextExtractor
  # Extracts plain text from a legacy binary .doc (Word 97-2003) file using
  # the antiword CLI tool. Requires `antiword` to be installed.
  #
  # antiword understands OLE2 compound documents and handles encoding issues
  # better than alternatives. Output is UTF-8 via the -w 0 flag (no line wrap).
  class Doc
    ANTIWORD_BIN = "antiword"

    def initialize(path)
      @path = path
    end

    def call
      stdout, stderr, status = Open3.capture3(ANTIWORD_BIN, "-w", "0", @path)

      unless status.success?
        # Some .doc files are actually RTF saved with a .doc extension
        return Rtf.new(@path).call if stderr.include?("probably a Rich Text Format file")

        raise "antiword failed (exit #{status.exitstatus}): #{stderr.strip}"
      end

      stdout.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
            .gsub(/[[:space:]]+/, " ").strip
    end
  end
end
