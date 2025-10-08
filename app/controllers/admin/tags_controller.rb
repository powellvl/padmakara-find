class Admin::TagsController < Admin::BaseController
  before_action :set_tag, only: %i[ show edit update destroy ]

  def index
    @tags = Tag.all
    add_breadcrumb "Tags", admin_tags_path

    respond_to do |format|
      format.html
      format.json { render json: @tags.select(:id, :name) }
    end
  end

  def available
    @tags = Tag.all.order(:name)
    render json: @tags.select(:id, :name)
  end

  def show
    add_breadcrumb "Tags", admin_tags_path
    add_breadcrumb @tag.name, admin_tag_path(@tag)
  end

  def new
    @tag = Tag.new
    add_breadcrumb "Tags", admin_tags_path
    add_breadcrumb "New Tag", new_admin_tag_path
  end

  def edit
    add_breadcrumb "Tags", admin_tags_path
    add_breadcrumb @tag.name, admin_tag_path(@tag)
    add_breadcrumb "Edit", edit_admin_tag_path(@tag)
  end

  def create
    @tag = Tag.new(tag_params)

    if @tag.save
      redirect_to admin_tag_path(@tag), notice: "Tag was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @tag.update(tag_params)
      redirect_to admin_tag_path(@tag), notice: "Tag was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tag.destroy!
    redirect_to admin_tags_path, notice: "Tag was successfully destroyed.", status: :see_other
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name)
  end
end
