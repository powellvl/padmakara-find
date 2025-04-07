class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_breadcrumbs

  def authorize_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end

  def add_breadcrumb(label, path)
    @breadcrumbs << {
      label: label,
      path: path
    }
  end

  def set_breadcrumbs
    @breadcrumbs = []
  end
end
