class Text < ApplicationRecord
  has_many :translations, dependent: :destroy
  validates :title_tibetan, presence: true
end
