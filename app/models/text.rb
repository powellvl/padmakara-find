class Text < ApplicationRecord
  has_many :translations, dependent: :destroy
  has_many_attached :files

  validates :title_tibetan, presence: true
  has_and_belongs_to_many :authors
  has_and_belongs_to_many :deities
  has_and_belongs_to_many :schools
  has_and_belongs_to_many :tags

  def cover_for_language(language_code)
    translation = translations.joins(:language).where(languages: { name: language_code }).first
    translation&.cover_file
  end

  def preferred_cover
    # Priorité: anglais, français, puis première traduction disponible
    cover_for_language("French") ||
    cover_for_language("English") ||
    translations.map(&:cover_file).compact.first
  end

  # Nouvelle méthode pour obtenir le nom de la dernière version publiée
  def latest_published_version_title(language_code)
    translation = translations.joins(:language).where(languages: { name: language_code }).first
    version = translation&.latest_published_version
    version&.title
  end

  # Méthode pour obtenir le nom de la version avec priorité (anglais, français, autres)
  def preferred_version_title
    latest_published_version_title("French") ||
    latest_published_version_title("English") ||
    translations.map { |t| t.latest_published_version&.title }.compact.first
  end
end
