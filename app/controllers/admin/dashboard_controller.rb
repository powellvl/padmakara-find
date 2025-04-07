class Admin::DashboardController < Admin::BaseController
  before_action :authorize_admin

  # Vous pouvez ajouter une authentification ou vérification ici
  # before_action :authenticate_admin!

  # GET /admin
  def index
    @page_title = "Admin Dashboard"

    @users_count = User.count
    @recent_activities = Activity.recent.limit(10) if defined?(Activity)

    # @users = User.all
    # @products = Product.all
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def authorize_admin
      unless Current.user&.admin?
        redirect_to root_path, alert: "Vous n'êtes pas autorisé à accéder à cette page."
      end
    end
end
