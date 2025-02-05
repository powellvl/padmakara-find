class Version < ApplicationRecord
  belongs_to :translation
  has_many_attached :files
  enum :status, { draft: 0, reviewing: 1, editing: 2, reviewing_edition: 3, published: 4 }
  validates :status, presence: true
  validates :name, uniqueness: { scope: :translation_id }, presence: true
end
