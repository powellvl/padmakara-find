class CataloguedFile < ApplicationRecord
  has_many :file_locations, dependent: :destroy

  enum :triage_state, { pending: 0, triaged: 1 }

  enum :extraction_status, {
    pending_extraction:  0,
    extracted:           1,
    extraction_failed:   2,
    unsupported_format:  3
  }

  validates :sha256_checksum, presence: true, uniqueness: true,
            format: { with: /\A[0-9a-f]{64}\z/, message: "must be a 64-character hex SHA-256" }
  validates :byte_size, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :content_type, presence: true
  validates :first_seen_at, presence: true
  validates :last_scan_at,  presence: true

  # ── Inventory scopes ───────────────────────────────────────────────────────

  scope :with_multiple_active_locations, -> {
    joins(:file_locations)
      .merge(FileLocation.active)
      .group(:id)
      .having("COUNT(file_locations.id) > 1")
  }

  # ── Full-text search ───────────────────────────────────────────────────────
  #
  # Searches content_tsvector (extracted text) and fuzzy-matches against
  # file_locations.path so that a filename query also works.
  # Uses the 'simple' text search config (no language-specific stemming) to
  # handle a multilingual corpus (French / English / future Tibetan).
  # Returns results ordered by full-text rank descending.

  scope :full_text_search, ->(query) {
    sanitized_query = sanitize_sql_for_conditions([ "plainto_tsquery('simple', ?)", query ])

    joins(:file_locations)
      .where(FileLocation.arel_table[:missing_since].eq(nil))
      .where(
        "catalogued_files.content_tsvector @@ #{sanitized_query} " \
        "OR file_locations.path ILIKE :like_q",
        like_q: "%#{sanitize_sql_like(query)}%"
      )
      .select(
        "DISTINCT ON (catalogued_files.id) catalogued_files.*, " \
        "ts_rank(catalogued_files.content_tsvector, #{sanitized_query}) AS rank, " \
        "ts_headline('simple', COALESCE(catalogued_files.extracted_text, ''), #{sanitized_query}, " \
        "'MaxWords=20, MinWords=5, ShortWord=3, MaxFragments=1') AS headline"
      )
      .order("catalogued_files.id, rank DESC")
  }

  # ── Helpers ────────────────────────────────────────────────────────────────

  def active_locations
    file_locations.active
  end

  def duplicate?
    active_locations.count > 1
  end

  # Updates the stored tsvector from the current extracted_text value.
  # Called by ExtractTextJob after a successful extraction.
  def update_tsvector!
    return if extracted_text.blank?

    self.class.where(id: id).update_all(
      self.class.sanitize_sql_array(
        [ "content_tsvector = to_tsvector('simple', ?)", extracted_text ]
      )
    )
  end
end
