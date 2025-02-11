class TranslationsController < ApplicationController
  before_action :set_text_and_breadcrumb
  before_action :set_translation_and_breadcrumb, only: %i[ edit update destroy ]

  # GET /texts/:id/translations or /translations.json
  def index
    @text = Text.find(params[:text_id])
    @translations = @text.translations
  end

  # GET /translations/new
  def new
    @text = Text.find(params[:text_id])
    @translation = @text.translations.build
    @available_languages = Language.all
    add_breadcrumb("New Translation", new_text_translation_path(@text))
  end

  # GET /translations/1/edit
  def edit
    @available_languages = Language.all
    add_breadcrumb("Edit", edit_text_translation_path(@text, @translation))
  end

  # POST /translations or /translations.json
  def create
    @translation = @text.translations.new(translation_params)

    if @translation.save
      redirect_to [ @text, @translation ], notice: "Translation was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /translations/1 or /translations/1.json
  def update
    if @translation.update(translation_params)
      redirect_to [ @text, @translation ], notice: "Translation was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /translations/1 or /translations/1.json
  def destroy
    @translation.destroy!
    redirect_to [ @text, :translations ], status: :see_other, notice: "Translation was successfully destroyed."
  end

  private
    def set_text_and_breadcrumb
      @text = Text.find(params.expect(:text_id))
      add_breadcrumb(@text.title_tibetan, text_translations_path(@text))
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_translation_and_breadcrumb
      @translation = Translation.find(params.expect(:id))
      add_breadcrumb(@translation.language, text_translation_path(@text, @translation))
    end

    # Only allow a list of trusted parameters through.
    def translation_params
      params.expect(translation: [ :language ])
    end
end
