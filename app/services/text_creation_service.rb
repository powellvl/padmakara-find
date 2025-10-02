# Service pour créer un texte avec ses traductions et versions en une seule opération
class TextCreationService
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Attributs pour le texte principal
  attribute :title_tibetan, :string
  attribute :title_phonetics, :string
  attribute :title_wylie, :string
  attribute :notes, :string
  attribute :author_ids, array: true, default: []
  attribute :deity_ids, array: true, default: []
  attribute :school_ids, array: true, default: []
  attribute :tag_ids, array: true, default: []

  # Attributs pour les traductions
  attribute :translations_attributes, default: {}

  # Fichiers uploadés directement sur le texte
  attribute :direct_files, array: true, default: []

  validates :title_tibetan, presence: true
  validates :title_phonetics, presence: true

  def initialize(params = {})
    super
    prepare_translations_attributes(params)
  end

  def call
    return false unless valid?

    ActiveRecord::Base.transaction do
      create_text
      create_translations_with_versions
      attach_direct_files
      true
    end
  rescue => e
    Rails.logger.error "Error creating text: #{e.message}"
    errors.add(:base, "Une erreur s'est produite lors de la création")
    false
  end

  def update
    return false unless valid?
    return false unless @text&.persisted?

    ActiveRecord::Base.transaction do
      update_text
      # Note: Pour la mise à jour, on se contente de mettre à jour les attributs du texte
      # La gestion des traductions/versions pourrait être ajoutée plus tard si nécessaire
      true
    end
  rescue => e
    Rails.logger.error "Error updating text: #{e.message}"
    errors.add(:base, "Une erreur s'est produite lors de la mise à jour")
    false
  end

  def text
    @text
  end

  def text=(text_object)
    @text = text_object
  end

  private

  def prepare_translations_attributes(params = {})
    # Préparer les attributs de traduction s'ils ne sont pas déjà structurés
    if params[:translations_attributes].present?
      self.translations_attributes = params[:translations_attributes]
    else
      self.translations_attributes = {}
    end
  end

  def create_text
    @text = Text.new(
      title_tibetan: title_tibetan,
      title_phonetics: title_phonetics,
      title_wylie: title_wylie,
      notes: notes,
      author_ids: clean_ids(author_ids),
      deity_ids: clean_ids(deity_ids),
      school_ids: clean_ids(school_ids),
      tag_ids: clean_ids(tag_ids)
    )

    @text.save!
  end

  def create_translations_with_versions
    translations_attributes.each do |_index, translation_attrs|
      next if translation_attrs["_destroy"] == "1" || translation_attrs[:language_id].blank?

      # Vérifier si la traduction a du contenu valide
      has_valid_content = false

      # Vérifier les fichiers de traduction
      if translation_attrs[:files].present? && translation_attrs[:files].any?(&:present?)
        has_valid_content = true
      end

      # Vérifier les versions
      if translation_attrs[:versions_attributes].present?
        translation_attrs[:versions_attributes].each do |_version_index, version_attrs|
          next if version_attrs["_destroy"] == "1"

          if version_attrs[:name].present? || version_attrs[:title].present? ||
             (version_attrs[:files].present? && version_attrs[:files].any?(&:present?))
            has_valid_content = true
            break
          end
        end
      end

      # Ne créer la traduction que si elle a du contenu valide
      create_single_translation(translation_attrs) if has_valid_content
    end
  end

  def create_single_translation(attrs)
    translation = @text.translations.build(
      language_id: attrs[:language_id]
    )
    translation.save!

    # Créer les versions pour cette traduction
    create_versions_for_translation(translation, attrs)

    # Attacher les fichiers directement à la traduction si fournis
    if attrs[:files].present?
      attrs[:files].each do |file|
        translation.files.attach(file) if file.present?
      end
    end
  end

  def create_versions_for_translation(translation, attrs)
    # Créer les versions à partir de versions_attributes
    if attrs[:versions_attributes].present?
      attrs[:versions_attributes].each do |_version_index, version_attrs|
        next if version_attrs["_destroy"] == "1" || version_attrs[:name].blank?

        version = translation.versions.build(
          name: version_attrs[:name],
          title: version_attrs[:title],
          subtitle: version_attrs[:subtitle],
          status: :draft
        )
        version.save!

        # Attacher les fichiers à cette version si fournis
        if version_attrs[:files].present?
          version_attrs[:files].each do |file|
            version.files.attach(file) if file.present?
          end
        end
      end
    end

    # Si aucune version n'a été créée mais qu'on a des données legacy, créer une version par défaut
    if translation.versions.empty? && (attrs[:version_title].present? || attrs[:version_name].present?)
      version = translation.versions.build(
        name: attrs[:version_name] || "Version 1",
        title: attrs[:version_title],
        subtitle: attrs[:version_subtitle],
        status: :draft
      )
      version.save!
    end
  end

  def attach_direct_files
    return if direct_files.blank?

    direct_files.each do |file|
      @text.files.attach(file) if file.present?
    end
  end

  def update_text
    @text.update!(
      title_tibetan: title_tibetan,
      title_phonetics: title_phonetics,
      title_wylie: title_wylie,
      notes: notes,
      author_ids: clean_ids(author_ids),
      deity_ids: clean_ids(deity_ids),
      school_ids: clean_ids(school_ids),
      tag_ids: clean_ids(tag_ids)
    )
  end

  def clean_ids(ids)
    Array(ids).reject(&:blank?).map(&:to_i)
  end
end
