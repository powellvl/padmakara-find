class Translation < ApplicationRecord
  belongs_to :text
  belongs_to :language
  has_many :versions, dependent: :destroy

  def latest_published_version
    versions.published.order(updated_at: :desc).first
  end

  def cover_file
    version = latest_published_version
    return nil unless version

    # Utiliser la cover générée si disponible, sinon le fichier primaire
    if version.cover.attached?
      version.cover
    else
      version.primary_file
    end
  end
end
