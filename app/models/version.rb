class Version < ApplicationRecord
  belongs_to :translation
  enum :status, { draft: 0, reviewing: 1, editing: 2, reviewing_edition: 3, published: 4 }
  validates :name, uniqueness: { scope: :translation_id }
end
