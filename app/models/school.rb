class School < ApplicationRecord
  has_and_belongs_to_many :texts
end
