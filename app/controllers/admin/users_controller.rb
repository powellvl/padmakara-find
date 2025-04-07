class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[ show edit update destroy ]

  def index
    @users = User.all
    add_breadcrumb "Users", admin_users_path
  end

  def show
    add_breadcrumb "Users", admin_users_path
    add_breadcrumb @user.email, admin_user_path(@user)
  end

  def new
    @user = User.new
    add_breadcrumb "Users", admin_users_path
    add_breadcrumb "New User", new_admin_user_path
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to admin_user_path(@user), notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    add_breadcrumb "Users", admin_users_path
    add_breadcrumb @user.email, admin_user_path(@user)
    add_breadcrumb "Edit", edit_admin_user_path(@user)
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: "User was successfully destroyed."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :role, :password, :password_confirmation)
  end
end
