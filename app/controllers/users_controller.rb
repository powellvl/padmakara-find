class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_admin, except: [ :show ]
  before_action :authorize_user_or_admin, only: [ :show ]

  def index
    @users = User.all
    add_breadcrumb("Users", users_path)
  end

  def show
    add_breadcrumb(@user.email, user_path(@user))
  end

  def new
    @user = User.new
    add_breadcrumb("New User", new_user_path)
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, notice: "User was successfully created."
      add_breadcrumb(@user.email, user_path(@user))
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    add_breadcrumb("Edit", edit_user_path(@user))
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "User was successfully updated."
      add_breadcrumb(@user.email, user_path(@user))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url, notice: "User was successfully destroyed."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :role, :password, :password_confirmation)
  end

  def add_breadcrumbs
    add_breadcrumb("Admin Dashboard", admin_path)
    add_breadcrumb("Users", users_path)
  end

  def authorize_user_or_admin
    unless Current.user&.admin? || Current.user == @user
      redirect_to root_path, alert: "Vous n'êtes pas autorisé à accéder à cette page."
    end
  end
end
