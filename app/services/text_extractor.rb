require_relative "text_extractor/pdf"
require_relative "text_extractor/docx"

# Dispatches to the right format-specific extractor and returns a result struct.
#
# Result:
#   status  — :extracted | :unsupported_format | :extraction_failed
#   text    — String (possibly empty) or nil
#   error   — exception message when status is :extraction_failed
class TextExtractor
  Result = Data.define(:status, :text, :error)

  EXTRACTORS = {
    "application/pdf"                                                                       => Pdf,
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"              => Docx,
    "application/msword"                                                                    => Docx
  }.freeze

  def initialize(path, content_type)
    @path         = path.to_s
    @content_type = content_type
  end

  def call
    extractor_class = EXTRACTORS[@content_type]
    return Result.new(status: :unsupported_format, text: nil, error: nil) unless extractor_class

    text = extractor_class.new(@path).call
    Result.new(status: :extracted, text: text.to_s.strip, error: nil)
  rescue => e
    Result.new(status: :extraction_failed, text: nil, error: e.message)
  end
end
