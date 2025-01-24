class Text < ApplicationRecord
  has_many :translations, dependent: :destroy
  validates :title_tibetan, presence: true
  has_and_belongs_to_many :deities
  has_and_belongs_to_many :schools
  has_and_belongs_to_many :tags
end
