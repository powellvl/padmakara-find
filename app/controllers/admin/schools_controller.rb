class Admin::SchoolsController < Admin::BaseController
  before_action :set_school, only: %i[ show edit update destroy ]

  def index
    @schools = School.all
    add_breadcrumb "Schools", admin_schools_path
  end

  def show
    add_breadcrumb "Schools", admin_schools_path
    add_breadcrumb @school.name, admin_school_path(@school)
  end

  def new
    @school = School.new
    add_breadcrumb "Schools", admin_schools_path
    add_breadcrumb "New School", new_admin_school_path
  end

  def edit
    add_breadcrumb "Schools", admin_schools_path
    add_breadcrumb @school.name, admin_school_path(@school)
    add_breadcrumb "Edit", edit_admin_school_path(@school)
  end

  def create
    @school = School.new(school_params)

    if @school.save
      redirect_to admin_school_path(@school), notice: "School was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @school.update(school_params)
      redirect_to admin_school_path(@school), notice: "School was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @school.destroy!
    redirect_to admin_schools_path, notice: "School was successfully destroyed.", status: :see_other
  end

  private

  def set_school
    @school = School.find(params[:id])
  end

  def school_params
    params.require(:school).permit(:name)
  end
end
