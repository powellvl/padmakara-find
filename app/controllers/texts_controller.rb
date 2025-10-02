class TextsController < ApplicationController
  before_action :authorize_admin, only: %i[ destroy ]
  before_action :set_text, only: %i[ edit update destroy ]
  # GET /texts or /texts.json
  def index
    @texts = Text.all

    # Nettoyage et stockage des paramètres pour la vue
    @selected_school_ids = params[:school_ids]&.reject(&:blank?) || []
    @selected_deity_ids = params[:deity_ids]&.reject(&:blank?) || []
    @selected_tag_ids = params[:tag_ids]&.reject(&:blank?) || []

    # Filtrage par schools
    if @selected_school_ids.any?
      @texts = @texts.joins(:schools).where(schools: { id: @selected_school_ids }).distinct
    end

    # Filtrage par deities
    if @selected_deity_ids.any?
      @texts = @texts.joins(:deities).where(deities: { id: @selected_deity_ids }).distinct
    end

    # Filtrage par tags
    if @selected_tag_ids.any?
      @texts = @texts.joins(:tags).where(tags: { id: @selected_tag_ids }).distinct
    end

    # Charger les données pour les filtres
    @schools = School.all.order(:name)
    @deities = Deity.all.order(:name_english)
    @tags = Tag.all.order(:name)
  end

  # GET /texts/new
  def new
    @text_service = TextCreationService.new
    @authors = Author.all.order(:name_english)
    @schools = School.all.order(:name)
    @deities = Deity.all.order(:name_english)
    @tags = Tag.all.order(:name)

    # Ordre spécifique des langues : tibétain, anglais, français, espagnol, portugais, allemand
    language_order = [ "tibetan", "english", "french", "spanish", "portuguese", "german" ]
    all_languages = Language.all
    @languages = all_languages.sort_by do |language|
      name_lower = language.name.downcase
      order_index = language_order.find_index { |lang| name_lower.include?(lang) }
      order_index || 999 # Mettre les langues non trouvées à la fin
    end

    add_breadcrumb("New Text", new_text_path)
  end

  # GET /texts/1/edit
  def edit
    # Initialiser le service d'édition avec le texte existant
    @text_service = TextCreationService.new.tap do |service|
      service.text = @text
      service.title_tibetan = @text.title_tibetan
      service.title_wylie = @text.title_wylie
      service.title_phonetics = @text.title_phonetics
      service.notes = @text.notes
      service.author_ids = @text.author_ids
      service.school_ids = @text.school_ids
      service.deity_ids = @text.deity_ids
      service.tag_ids = @text.tag_ids
    end

    # Charger les données pour les formulaires
    @authors = Author.all.order(:name_english)
    @schools = School.all.order(:name)
    @deities = Deity.all.order(:name_english)
    @tags = Tag.all.order(:name)

    # Ordre spécifique des langues
    language_order = [ "tibetan", "english", "french", "spanish", "portuguese", "german" ]
    all_languages = Language.all
    @languages = all_languages.sort_by do |language|
      name_lower = language.name.downcase
      order_index = language_order.find_index { |lang| name_lower.include?(lang) }
      order_index || 999
    end

    add_breadcrumb("Edit", edit_text_path(@text))
  end

  # POST /texts or /texts.json
  def create
    @text_service = TextCreationService.new(text_service_params)

    if @text_service.call
      redirect_to text_translations_path(@text_service.text),
                  notice: "Text was successfully created with #{@text_service.text.translations.count} translation(s)."
    else
      @authors = Author.all.order(:name)
      @schools = School.all.order(:name)
      @deities = Deity.all.order(:name_english)
      @tags = Tag.all.order(:name)
      @languages = Language.all.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /texts/1 or /texts/1.json
  def update
    if params[:text_creation_service]
      # Mise à jour via le service de création (formulaire complexe)
      @text_service = TextCreationService.new(text_service_params.merge(text: @text))

      if @text_service.update
        redirect_to text_translations_path(@text), notice: "Text was successfully updated."
      else
        @authors = Author.all.order(:name_english)
        @schools = School.all.order(:name)
        @deities = Deity.all.order(:name_english)
        @tags = Tag.all.order(:name)

        language_order = [ "tibetan", "english", "french", "spanish", "portuguese", "german" ]
        all_languages = Language.all
        @languages = all_languages.sort_by do |language|
          name_lower = language.name.downcase
          order_index = language_order.find_index { |lang| name_lower.include?(lang) }
          order_index || 999
        end

        render :edit, status: :unprocessable_entity
      end
    else
      # Mise à jour simple (au cas où)
      if @text.update(text_params)
        redirect_to texts_path, notice: "Text was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  # DELETE /texts/1 or /texts/1.json
  def destroy
    @text.destroy!
    redirect_to texts_path, status: :see_other, notice: "Text was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_text
      @text = Text.find(params[:id])
      add_breadcrumb(@text.title_phonetics, text_path(@text))
    end
    # Only allow a list of trusted parameters through.
    def text_params
      params.require(:text).permit(:title_tibetan, :title_wylie, :title_phonetics, :notes, deity_ids: [], school_ids: [], tag_ids: [], author_ids: [])
    end

    def text_service_params
      params.require(:text_creation_service).permit(
        :title_tibetan, :title_wylie, :title_phonetics, :notes,
        author_ids: [], deity_ids: [], school_ids: [], tag_ids: [],
        direct_files: [],
        translations_attributes: {}
      ).tap do |permitted_params|
        # Permettre les attributs imbriqués pour les traductions
        if params[:text_creation_service][:translations_attributes]
          permitted_params[:translations_attributes] = params[:text_creation_service][:translations_attributes].permit!
        end
      end
    end
end
