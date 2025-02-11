class Language < ApplicationRecord
  has_many :translations
  validates :name, presence: true, uniqueness: true
end
