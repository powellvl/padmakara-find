class TextsController < ApplicationController
  before_action :authorize_admin, only: %i[ destroy ]
  before_action :set_text, only: %i[ edit update destroy ]
  # GET /texts or /texts.json
  def index
    @texts = Text.all
  end

  # GET /texts/new
  def new
    @text = Text.new
    add_breadcrumb("New Text", new_text_path)
  end

  # GET /texts/1/edit
  def edit
    add_breadcrumb("Edit", edit_text_path(@text))
  end

  # POST /texts or /texts.json
  def create
    @text = Text.new(text_params)

    if @text.save
      redirect_to texts_path, notice: "Text was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /texts/1 or /texts/1.json
  def update
      if @text.update(text_params)
        redirect_to texts_path, notice: "Text was successfully updated."
      else
        render :edit, status: :unprocessable_entity
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
      add_breadcrumb(@text.title_tibetan, text_path(@text))
    end
    # Only allow a list of trusted parameters through.
    def text_params
      params.require(:text).permit(:title_tibetan, :title_phonetics, :notes, deity_ids: [], school_ids: [], tag_ids: [])
    end
end
