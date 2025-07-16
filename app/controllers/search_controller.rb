class SearchController < ApplicationController
  def index
    # Nettoyage et stockage des paramètres pour la vue
    @selected_school_ids = params[:school_ids]&.reject(&:blank?) || []
    @selected_deity_ids = params[:deity_ids]&.reject(&:blank?) || []
    @selected_tag_ids = params[:tag_ids]&.reject(&:blank?) || []
    @selected_content_types = params[:content_types]&.reject(&:blank?) || [ "texts", "versions", "files" ]

    # Charger les données pour les filtres
    @schools = School.all.order(:name)
    @deities = Deity.all.order(:name_english)
    @tags = Tag.all.order(:name)

    # Options de types de contenu
    @content_type_options = [
      { id: "texts", name: "Texts", icon: "\u{1F4DA}" },
      { id: "versions", name: "Versions", icon: "\u{1F4C4}" },
      { id: "files", name: "Files", icon: "\u{1F4CE}" }
    ]

    @query = params[:query]

    # Initialiser les collections
    @texts = []
    @versions = []
    @files = []

    if @query.present?
      # Recherche dans les textes si sélectionné
      if @selected_content_types.include?("texts")
        @texts = build_text_search_query(@query)
        @texts = apply_filters_to_texts(@texts)
      end

      # Recherche dans les versions si sélectionné
      if @selected_content_types.include?("versions")
        @versions = build_version_search_query(@query)
        @versions = apply_filters_to_versions(@versions)
      end

      # Recherche dans les fichiers si sélectionné
      if @selected_content_types.include?("files")
        @files = build_file_search_query(@query)
        @files = apply_filters_to_files(@files)
      end
    else
      # Si pas de recherche mais filtres appliqués
      if @selected_school_ids.any? || @selected_deity_ids.any? || @selected_tag_ids.any?
        # Afficher les textes si sélectionné
        if @selected_content_types.include?("texts")
          @texts = Text.all
          @texts = apply_filters_to_texts(@texts)
        end

        # Afficher les versions si sélectionné
        if @selected_content_types.include?("versions")
          @versions = Version.joins(translation: :text)
          @versions = apply_filters_to_versions(@versions)
        end

        # Ne pas afficher les fichiers sans recherche de texte
      end
    end
  end

  private

  def build_text_search_query(query)
    Text.distinct
        .joins(translations: { versions: { files_attachments: :blob } })
        .where("
          texts.title_tibetan LIKE :query
          OR texts.title_phonetics LIKE :query
          OR texts.title_wylie LIKE :query
          OR versions.title LIKE :query
          OR versions.subtitle LIKE :query
          OR active_storage_blobs.filename LIKE :query",
          query: "%#{query}%")
  end

  def build_version_search_query(query)
    Version.distinct
          .joins(files_attachments: :blob)
          .where("
          versions.title LIKE :query
          OR versions.subtitle LIKE :query
          OR versions.name LIKE :query
          OR active_storage_blobs.filename LIKE :query",
          query: "%#{query}%")
  end

  def build_file_search_query(query)
    ActiveStorage::Blob.where("filename LIKE :query", query: "%#{query}%")
  end

  def apply_filters_to_texts(texts_scope)
    # Filtrage par schools
    if @selected_school_ids.any?
      texts_scope = texts_scope.joins(:schools).where(schools: { id: @selected_school_ids }).distinct
    end

    # Filtrage par deities
    if @selected_deity_ids.any?
      texts_scope = texts_scope.joins(:deities).where(deities: { id: @selected_deity_ids }).distinct
    end

    # Filtrage par tags
    if @selected_tag_ids.any?
      texts_scope = texts_scope.joins(:tags).where(tags: { id: @selected_tag_ids }).distinct
    end

    texts_scope
  end

  def apply_filters_to_versions(versions_scope)
    # Filtrage par schools via les textes
    if @selected_school_ids.any?
      versions_scope = versions_scope.joins(translation: { text: :schools })
        .where(schools: { id: @selected_school_ids })
        .distinct
    end

    # Filtrage par deities via les textes
    if @selected_deity_ids.any?
      versions_scope = versions_scope.joins(translation: { text: :deities })
        .where(deities: { id: @selected_deity_ids })
        .distinct
    end

    # Filtrage par tags via les textes
    if @selected_tag_ids.any?
      versions_scope = versions_scope.joins(translation: { text: :tags })
      .where(tags: { id: @selected_tag_ids })
      .distinct
    end

    versions_scope
  end

  def apply_filters_to_files(files_scope)
    # Pour les fichiers, on doit les filtrer via les versions qui les contiennent
    if @selected_school_ids.any? || @selected_deity_ids.any? || @selected_tag_ids.any?
      # Trouver les versions qui correspondent aux filtres
      filtered_versions = Version.joins(translation: :text)

      if @selected_school_ids.any?
        filtered_versions = filtered_versions.joins(translation: { text: :schools })
        .where(schools: { id: @selected_school_ids })
      end

      if @selected_deity_ids.any?
        filtered_versions = filtered_versions.joins(translation: { text: :deities })
        .where(deities: { id: @selected_deity_ids })
      end

      if @selected_tag_ids.any?
        filtered_versions = filtered_versions.joins(translation: { text: :tags })
        .where(tags: { id: @selected_tag_ids })
      end

      # Obtenir les IDs des versions filtrées
      version_ids = filtered_versions.distinct.pluck(:id)

      # Filtrer les fichiers pour ne garder que ceux attachés à ces versions
      if version_ids.any?
        files_scope = files_scope.joins(:attachments)
        .where(active_storage_attachments: {
        record_type: "Version",
        record_id: version_ids })
      else
        # Si aucune version ne correspond aux filtres, retourner une collection vide
        files_scope = files_scope.none
      end
    end

    files_scope
  end
end
