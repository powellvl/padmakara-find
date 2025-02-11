module ApplicationHelper
  def is_last?(index, collection)
    index == collection.size - 1
  end
end
