# Review humaine des propositions de triage par dossier : l'IA propose des
# groupes Text/Translation/Version pour un dossier, un humain valide ou rejette
# avant toute écriture dans le catalogue.
class FolderTriageController < ApplicationController
  before_action :authorize_admin
  before_action :set_proposal, only: %i[show accept reject]

  def index
    @proposals = FolderTriageProposal.proposed.order(created_at: :asc)
    @stats = FolderTriageProposal.group(:status).count
  end

  def show
    # Les fichiers référencés par les groupes, avec leur carte IA, pour affichage
    file_ids = @proposal.groups.flat_map { |g| Array(g["files"]).map { |f| f["id"] } } +
               Array(@proposal.payload&.dig("unassigned_file_ids"))
    @files_by_id = CataloguedFile.where(id: file_ids.compact.uniq)
                                 .includes(:file_locations)
                                 .index_by(&:id)
  end

  # Aperçu de la 1re page d'un PDF du NAS : c'est la PREUVE que le relecteur
  # compare au titre proposé, sans avoir à lire le tibétain ni ouvrir le fichier.
  def preview
    cf = CataloguedFile.find(params[:id])
    image = PdfPagePreview.new(cf).call

    if image
      send_data image, type: "image/jpeg", disposition: "inline"
    else
      head :not_found
    end
  end

  def accept
    result = FolderCatalogApplier.new(@proposal).call

    if result.error
      redirect_to folder_triage_path(@proposal), alert: "Échec de l'application : #{result.error}"
    else
      redirect_to folder_triage_index_path,
                  notice: "Dossier catalogué : #{result.texts.size} texte(s), #{result.versions_count} version(s)."
    end
  end

  def reject
    @proposal.update!(status: :rejected)
    redirect_to folder_triage_index_path, notice: "Proposition rejetée."
  end

  private

  def set_proposal
    @proposal = FolderTriageProposal.find(params[:id])
  end
end
