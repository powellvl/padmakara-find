class CoversController < ApplicationController
  before_action :authorize_admin
  before_action :set_version

  # POST /versions/:id/generate_cover
  def generate
    if @version.generate_cover
      redirect_to [ @version.translation.text, @version.translation, @version ],
                  notice: "La couverture a été générée avec succès."
    else
      redirect_to [ @version.translation.text, @version.translation, @version ],
                  alert: "Impossible de générer la couverture. Assurez-vous qu'un fichier PDF primaire est défini."
    end
  end

  # DELETE /versions/:id/remove_cover
  def remove
    if @version.cover.attached?
      @version.cover.purge
      redirect_to [ @version.translation.text, @version.translation, @version ],
                  notice: "La couverture a été supprimée."
    else
      redirect_to [ @version.translation.text, @version.translation, @version ],
                  alert: "Aucune couverture à supprimer."
    end
  end

  private

  def set_version
    @version = Version.find(params[:id])
  end
end
