class VersionsController < ApplicationController
  before_action :set_text_and_breadcrumb
  before_action :set_translation_and_breadcrumb
  before_action :set_version_and_breadcrumb, only: %i[ show edit edit_files update destroy ]

  def index
    @versions = @translation.versions
  end

  def new
    @version = @translation.versions.new
    add_breadcrumb("New Version", new_text_translation_version_path(@text, @translation))
  end

  def edit
    add_breadcrumb("Edit", edit_text_translation_version_path(@text, @translation, @version))
  end

  def edit_files
    add_breadcrumb("Edit Files", edit_files_text_translation_version_path(@text, @translation, @version))
  end

  def show
  end

  def create
    @version = @translation.versions.new(version_params)

    if @version.save
      redirect_to [ @text, @translation, :versions ],
                  notice: "Version was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @version = Version.find(params[:id])

    Version.transaction do
      if params[:primary_file_id].present?
        # Réinitialiser tous les fichiers comme non-prioritaires
        @version.files_attachments.update_all(primary: false)
        # Définir le nouveau fichier prioritaire
        attachment = @version.files_attachments.find(params[:primary_file_id])
        attachment.update!(primary: true)
      end

      if @version.update(version_params)
        redirect_to [ @text, @translation, :versions ],
                    notice: "Version was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @version.destroy!
    redirect_to [ @text, @translation, :versions ],
                status: :see_other,
                notice: "Version was successfully destroyed."
  end

  private
    def set_text_and_breadcrumb
      @text = Text.find(params[:text_id])
      add_breadcrumb(@text.title_tibetan, text_translations_path(@text))
    end

    def set_translation_and_breadcrumb
      @translation = @text.translations.find(params[:translation_id])
      add_breadcrumb(@translation.language.name, text_translation_versions_path(@text, @translation))
    end

    def set_version_and_breadcrumb
      @version = @translation.versions.find(params[:id])
      add_breadcrumb(@version.name, text_translation_version_path(@text, @translation, @version))
    end

    def version_params
      params.require(:version).permit(:name, :status, files: [], primary_file_id: [])
    end
end
