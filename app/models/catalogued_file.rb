class CataloguedFile < ApplicationRecord
  has_many :file_locations, dependent: :destroy

  enum :triage_state, { pending: 0, triaged: 1 }

  validates :sha256_checksum, presence: true, uniqueness: true,
            format: { with: /\A[0-9a-f]{64}\z/, message: "must be a 64-character hex SHA-256" }
  validates :byte_size, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :content_type, presence: true
  validates :first_seen_at, presence: true
  validates :last_scan_at,  presence: true

  scope :with_multiple_active_locations, -> {
    joins(:file_locations)
      .merge(FileLocation.active)
      .group(:id)
      .having("COUNT(file_locations.id) > 1")
  }

  def active_locations
    file_locations.active
  end

  def duplicate?
    active_locations.count > 1
  end
end
