class VersionsController < ApplicationController
  before_action :set_text
  before_action :set_translation
  before_action :set_version, only: %i[ show edit edit_files update destroy ]

  def index
    @versions = @translation.versions
  end

  def new
    @version = @translation.versions.new
  end

  def edit
  end

  def edit_files
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
    if @version.update(version_params)
      redirect_to [ @text, @translation, :versions ],
                  notice: "Version was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @version.destroy!
    redirect_to [ @text, @translation, :versions ],
                status: :see_other,
                notice: "Version was successfully destroyed."
  end

  private
    def set_text
      @text = Text.find(params[:text_id])
    end

    def set_translation
      @translation = @text.translations.find(params[:translation_id])
    end

    def set_version
      @version = @translation.versions.find(params[:id])
    end

    def version_params
      params.expect({
        version: [ :name, :status, files: [] ]
      })
    end
end
