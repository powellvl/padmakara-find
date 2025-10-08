module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings
  end

  def tag_list
    tags.pluck(:name).join(", ")
  end

  def tag_list=(names)
    tag_names = names.split(",").map(&:strip).reject(&:blank?)
    self.tags = tag_names.map do |name|
      Tag.find_or_create_by(name: name)
    end
  end

  def add_tag(tag)
    tag = Tag.find_or_create_by(name: tag) if tag.is_a?(String)
    tags << tag unless tags.include?(tag)
  end

  def remove_tag(tag)
    tag = Tag.find_by(name: tag) if tag.is_a?(String)
    tags.delete(tag) if tag
  end

  def has_tag?(tag_name)
    tags.exists?(name: tag_name)
  end
end
