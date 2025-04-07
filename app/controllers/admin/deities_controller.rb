class Admin::DeitiesController < Admin::BaseController
  before_action :set_deity, only: %i[ show edit update destroy ]

  def index
    @deities = Deity.all
    add_breadcrumb "Deities", admin_deities_path
  end

  def show
    add_breadcrumb "Deities", admin_deities_path
    add_breadcrumb @deity.name_english, admin_deity_path(@deity)
  end

  def new
    @deity = Deity.new
    add_breadcrumb "Deities", admin_deities_path
    add_breadcrumb "New Deity", new_admin_deity_path
  end

  def edit
    add_breadcrumb "Deities", admin_deities_path
    add_breadcrumb @deity.name_english, admin_deity_path(@deity)
    add_breadcrumb "Edit", edit_admin_deity_path(@deity)
  end

  def create
    @deity = Deity.new(deity_params)

    if @deity.save
      redirect_to admin_deity_path(@deity), notice: "Deity was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @deity.update(deity_params)
      redirect_to admin_deity_path(@deity), notice: "Deity was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @deity.destroy!
    redirect_to admin_deities_path, notice: "Deity was successfully destroyed.", status: :see_other
  end

  private

  def set_deity
    @deity = Deity.find(params[:id])
  end

  def deity_params
    params.require(:deity).permit(:name_tibetan, :name_sanskrit, :name_english)
  end
end
