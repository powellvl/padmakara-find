class Version < ApplicationRecord
  belongs_to :translation
  has_many_attached :files
  has_one_attached :cover

  enum :status, { draft: 0, reviewing: 1, editing: 2, reviewing_edition: 3, published: 4 }

  validates :status, presence: true
  validates :name, uniqueness: { scope: :translation_id }, presence: true

  # Méthodes pour la gestion des fichiers
  def primary_file
    return nil unless files.attached?

    primary_attachment = files_attachments.find_by(primary: true)
    primary_attachment&.blob
  end

  def generate_cover
    ExtractPdfCover.new(self).call
  end

  # Callback après changement de statut
  after_update :update_text_cover_if_published

  private

  def update_text_cover_if_published
    if saved_change_to_status? && published?
      UpdateTextCover.new(translation.text).call
    end
  end
end
