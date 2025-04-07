class Admin::BaseController < ApplicationController
  before_action :authorize_admin
  before_action :add_admin_breadcrumb

  private

  def authorize_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Vous n'êtes pas autorisé à accéder à cette page."
    end
  end

  def add_admin_breadcrumb
    add_breadcrumb "Admin Dashboard", admin_path
  end
end
