class AiTriageProposal < ApplicationRecord
  belongs_to :catalogued_file

  enum :status, {
    pending_review: 0,
    accepted:       1,
    rejected:       2,
    skipped:        3
  }

  CONFIDENCE_LEVELS = %w[low medium high].freeze

  validates :catalogued_file, presence: true
  validates :confidence, inclusion: { in: CONFIDENCE_LEVELS }, allow_nil: true

  scope :awaiting_review, -> { where(status: :pending_review) }
  scope :for_prayer_texts, -> { where(is_prayer_text: true) }

  def low_confidence?
    confidence == "low"
  end
end
