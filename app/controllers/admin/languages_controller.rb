class Admin::LanguagesController < Admin::BaseController
  before_action :set_language, only: %i[ show edit update destroy ]

  def index
    @languages = Language.all
    add_breadcrumb "Languages", admin_languages_path
  end

  def show
    add_breadcrumb "Languages", admin_languages_path
    add_breadcrumb @language.name, admin_language_path(@language)
  end

  def new
    @language = Language.new
    add_breadcrumb "Languages", admin_languages_path
    add_breadcrumb "New Language", new_admin_language_path
  end

  def edit
    add_breadcrumb "Languages", admin_languages_path
    add_breadcrumb @language.name, admin_language_path(@language)
    add_breadcrumb "Edit", edit_admin_language_path(@language)
  end

  def create
    @language = Language.new(language_params)

    if @language.save
      redirect_to admin_language_path(@language), notice: "Language was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @language.update(language_params)
      redirect_to admin_language_path(@language), notice: "Language was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @language.destroy!
    redirect_to admin_languages_path, notice: "Language was successfully destroyed.", status: :see_other
  end

  private

  def set_language
    @language = Language.find(params[:id])
  end

  def language_params
    params.require(:language).permit(:name)
  end
end
