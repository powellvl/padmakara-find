class TranslationsController < ApplicationController
  before_action :set_text
  before_action :set_translation, only: %i[ edit update destroy ]

  # GET /texts/:id/translations or /translations.json
  def index
    @text = Text.find(params[:text_id])
    @translations = @text.translations
  end

  # GET /translations/new
  def new
    @translation = @text.translations.new
  end

  # GET /translations/1/edit
  def edit
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
      redirect_to @translation, notice: "Translation was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /translations/1 or /translations/1.json
  def destroy
    @translation.destroy!
    redirect_to translations_path, status: :see_other, notice: "Translation was successfully destroyed."
  end

  private
    def set_text
      @text = Text.find(params.expect(:text_id))
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_translation
      @translation = Translation.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def translation_params
      params.expect(translation: [ :language ])
    end
end
