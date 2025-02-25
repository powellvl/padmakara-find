class LanguagesController < ApplicationController
  before_action :set_language, only: %i[ show edit update destroy ]

  # GET /languages
  def index
    @languages = Language.all
    add_breadcrumb "Languages", languages_path
  end

  # GET /languages/1
  def show
    add_breadcrumb "Languages", languages_path
    add_breadcrumb @language.name, language_path(@language)
  end

  # GET /languages/new
  def new
    @language = Language.new
    add_breadcrumb "Languages", languages_path
    add_breadcrumb "New Language", new_language_path
  end

  # GET /languages/1/edit
  def edit
    add_breadcrumb "Languages", languages_path
    add_breadcrumb @language.name, language_path(@language)
    add_breadcrumb "Edit", edit_language_path(@language)
  end

  # POST /languages
  def create
    @language = Language.new(language_params)

    if @language.save
      redirect_to @language, notice: "Language was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /languages/1
  def update
    if @language.update(language_params)
      redirect_to @language, notice: "Language was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /languages/1
  def destroy
    @language.destroy!
    redirect_to languages_path, notice: "Language was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_language
      @language = Language.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def language_params
      params.expect(language: [ :name ])
    end
end
