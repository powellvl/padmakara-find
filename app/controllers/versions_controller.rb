class VersionsController < ApplicationController
  before_action :authorize_admin, only: %i[ destroy ]
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
    respond_to do |format|
      # Gérer le changement de fichier primaire
      if params[:primary_file_id].present?
        attachment = @version.files_attachments.find(params[:primary_file_id])
        service = DefineVersionFileAsPrimary.new(@version, attachment)

        unless service.call
          format.html { redirect_to [ @text, @translation, @version ], alert: "Erreur lors de la définition du fichier primaire." }
          return
        end
      end

      if @version.update(version_params)
        format.html { redirect_to [ @text, @translation, @version ], notice: "Version mise à jour avec succès." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @version.destroy!
    redirect_to [ @text, @translation, :versions ],
                status: :see_other,
                notice: "Version was successfully destroyed."
  end

  # POST /texts/1/translations/2/versions/3/files/123/add_tags
  def add_file_tags
    file_attachment = @version.files.find(params[:file_id])

    if file_attachment && params[:tag_ids].present?
      begin
        tags_to_add = Tag.where(id: params[:tag_ids])

        # Ajouter les tags qui ne sont pas déjà associés
        tags_to_add.each do |tag|
          unless file_attachment.tags.include?(tag)
            file_attachment.tags << tag
          end
        end

        render json: {
          status: "success",
          message: "Tags ajoutés avec succès",
          tags: tags_to_add.map { |tag| { id: tag.id, name: tag.name } }
        }
      rescue => e
        render json: {
          status: "error",
          message: "Erreur lors de l'ajout des tags: #{e.message}"
        }, status: :unprocessable_entity
      end
    else
      render json: {
        status: "error",
        message: "Fichier ou tags non trouvés"
      }, status: :unprocessable_entity
    end
  end

  # DELETE /texts/1/translations/2/versions/3/files/123/remove_tag/456
  def remove_file_tag
    file_attachment = @version.files.find(params[:file_id])

    if file_attachment
      begin
        tag = Tag.find(params[:tag_id])

        # Supprimer la relation entre le fichier et le tag
        file_attachment.tags.delete(tag)

        render json: {
          status: "success",
          message: "Tag supprimé avec succès"
        }
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: "error",
          message: "Tag non trouvé"
        }, status: :not_found
      rescue => e
        render json: {
          status: "error",
          message: "Erreur lors de la suppression du tag: #{e.message}"
        }, status: :unprocessable_entity
      end
    else
      render json: {
        status: "error",
        message: "Fichier non trouvé"
      }, status: :not_found
    end
  end

  private
    def set_text_and_breadcrumb
      @text = Text.find(params[:text_id])
      add_breadcrumb(@text.title_phonetics, text_translations_path(@text))
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
      params.require(:version).permit(:title, :subtitle, :name, :status, files: [], primary_file_id: [])
    end
end
