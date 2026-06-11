class Translation < ApplicationRecord
  belongs_to :text
  belongs_to :language
  has_many :versions, dependent: :destroy

  def latest_published_version
    versions.published.order(updated_at: :desc).first
  end

  # Version to show in listings: the latest published one, or — for content
  # triaged from the NAS that is still in draft — the latest version available.
  def display_version
    latest_published_version || versions.order(updated_at: :desc).first
  end

  def cover_file
    version = display_version
    return nil unless version

    # Utiliser la cover générée si disponible, sinon le fichier primaire
    if version.cover.attached?
      version.cover
    else
      version.primary_file
    end
  end
end
