module ApplicationHelper
  def is_last?(index, collection)
    index == collection.size - 1
  end

  def file_icon_path(filename)
    extension = File.extname(filename.to_s).downcase.delete(".")
    case extension
    when "doc", "docx"
      "icons/doc-file.svg"
    when "indd"
      "icons/indd-file.svg"
    when "pdf"
      "icons/pdf-file.svg"
    else
      nil
    end
  end
end
