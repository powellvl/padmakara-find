class SchoolsController < ApplicationController
  before_action :authorize_admin
  before_action :set_school_and_breadcrumb, only: %i[ show edit update destroy ]

  # GET /schools
  def index
    @schools = School.all
    add_breadcrumb("Admin Dashboard", admin_path)
    add_breadcrumb("Schools", schools_path)
  end

  # GET /schools/1
  def show
  end

  # GET /schools/new
  def new
    @school = School.new
    add_breadcrumb("Admin Dashboard", admin_path)
    add_breadcrumb("Schools", schools_path)
    add_breadcrumb("New School", new_school_path)
  end

  # GET /schools/1/edit
  def edit
  end

  # POST /schools
  def create
    @school = School.new(school_params)

    if @school.save
      redirect_to @school, notice: "School was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /schools/1
  def update
    if @school.update(school_params)
      redirect_to @school, notice: "School was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /schools/1
  def destroy
    @school.destroy!
    redirect_to schools_path, notice: "School was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_school_and_breadcrumb
      @school = School.find(params.expect(:id))
      add_breadcrumb "Admin Dashboard", admin_path
      add_breadcrumb(@school.name, school_path(@school))
    end

    def authorize_admin
      unless Current.user&.admin?
        redirect_to root_path, alert: "Vous n'êtes pas autorisé à accéder à cette page."
      end
    end

    # Only allow a list of trusted parameters through.
    def school_params
      params.expect(school: [ :name ])
    end
end
