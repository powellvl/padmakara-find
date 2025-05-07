class Text < ApplicationRecord
  has_many :translations, dependent: :destroy
  validates :title_tibetan, presence: true
  has_and_belongs_to_many :deities
  has_and_belongs_to_many :schools
  has_and_belongs_to_many :tags

  def cover_for_language(language_code)
    translation = translations.joins(:language).where(languages: { name: language_code }).first
    translation&.cover_file
  end

  def preferred_cover
    # Priorité: anglais, français, puis première traduction disponible
    cover_for_language("English") ||
    cover_for_language("French") ||
    translations.map(&:cover_file).compact.first
  end
end
