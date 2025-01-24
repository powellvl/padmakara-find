class Translation < ApplicationRecord
  has_many :versions, dependent: :destroy
  belongs_to :text
end
