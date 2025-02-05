module VersionsHelper
  def status_color_classes(status)
    case status
    when "draft"
      "bg-red-100 text-red-700"
    when "reviewing"
      "bg-yellow-100 text-yellow-700"
    when "editing"
      "bg-blue-100 text-blue-700"
    when "reviewing_edition"
      "bg-purple-100 text-purple-700"
    when "published"
      "bg-green-100 text-green-700"
    else
      "bg-gray-100 text-gray-700"
    end
  end
end
