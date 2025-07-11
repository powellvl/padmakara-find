class Admin::AuthorsController < Admin::BaseController
  before_action :set_author, only: %i[ show edit update destroy ]

  def index
    @authors = Author.all
    add_breadcrumb "Authors", admin_authors_path
  end

  def show
    add_breadcrumb "Authors", admin_authors_path
    add_breadcrumb @author.name_english, admin_author_path(@author)
  end

  def new
    @author = Author.new
    add_breadcrumb "Authors", admin_authors_path
    add_breadcrumb "New Author", new_admin_author_path
  end

  def edit
    add_breadcrumb "Authors", admin_authors_path
    add_breadcrumb @author.name_english, admin_author_path(@author)
    add_breadcrumb "Edit", edit_admin_author_path(@author)
  end

  def create
    @author = Author.new(author_params)

    if @author.save
      redirect_to admin_author_path(@author), notice: "Author was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @author.update(author_params)
      redirect_to admin_author_path(@author), notice: "Author was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @author.destroy!
    redirect_to admin_authors_path, notice: "Author was successfully destroyed.", status: :see_other
  end

  private

  def set_author
    @author = Author.find(params[:id])
  end

  def author_params
    params.require(:author).permit(:name_tibetan, :name_sanskrit, :name_english)
  end
end
