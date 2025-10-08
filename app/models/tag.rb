class Tag < ApplicationRecord
  has_and_belongs_to_many :texts
  has_many :taggings, dependent: :destroy

  # Méthodes polymorphiques pour récupérer les différents types d'objets taggés
  def active_storage_attachments
    taggings.where(taggable_type: "ActiveStorage::Attachment").includes(:taggable).map(&:taggable)
  end
end
