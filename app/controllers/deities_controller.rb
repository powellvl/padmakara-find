class DeitiesController < ApplicationController
  before_action :set_deity, only: %i[ show edit update destroy ]

  # GET /deities
  def index
    @deities = Deity.all
    add_breadcrumb "Deities", deities_path
  end

  # GET /deities/1
  def show
    add_breadcrumb "Deities", deities_path
    add_breadcrumb @deity.name_english, deity_path(@deity)
  end

  # GET /deities/new
  def new
    @deity = Deity.new
    add_breadcrumb "Deities", deities_path
    add_breadcrumb "New Deity", new_deity_path
  end

  # GET /deities/1/edit
  def edit
    add_breadcrumb "Deities", deities_path
    add_breadcrumb @deity.name_english, deity_path(@deity)
    add_breadcrumb "Edit", edit_deity_path(@deity)
  end

  # POST /deities
  def create
    @deity = Deity.new(deity_params)

    if @deity.save
      redirect_to @deity, notice: "Deity was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /deities/1
  def update
    if @deity.update(deity_params)
      redirect_to @deity, notice: "Deity was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /deities/1
  def destroy
    @deity.destroy!
    redirect_to deities_path, notice: "Deity was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_deity
      @deity = Deity.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def deity_params
      params.expect(deity: [ :name_tibetan, :name_sanskrit, :name_english ])
    end
end
