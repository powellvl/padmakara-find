class FolderTriageProposal < ApplicationRecord
  enum :status, {
    proposed: 0,
    applied:  1,
    failed:   2,
    rejected: 3
  }

  validates :folder_path, presence: true

  def groups
    (payload || {})["groups"] || []
  end
end
