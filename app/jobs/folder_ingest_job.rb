# Ingère un dossier du NAS en une unité : construit les cartes IA manquantes
# de ses fichiers, puis crée une FolderTriageProposal en attente de review.
#
# Un job = un dossier = une proposition. Pas d'ordonnancement inter-jobs : le
# dossier est autonome. Résumable (saute les cartes déjà faites et les dossiers
# déjà proposés/appliqués) et tolérant aux limites de débit (retry).
class FolderIngestJob < ApplicationJob
  queue_as :ingest

  # Les erreurs de limite de débit du fournisseur IA sont rejouées avec backoff.
  class RateLimitError < StandardError; end

  RATE_LIMIT_RE = /429|rate.?limit|too many requests/i

  retry_on RateLimitError, wait: :polynomially_longer, attempts: 6
  # Un dossier introuvable (déplacé entre le scan et le job) est ignoré.
  discard_on ActiveJob::DeserializationError

  # folder_path : chemin RELATIF à NasSource.root (tel que stocké dans les proposals)
  def perform(folder_path)
    abs = File.join(NasSource.root.to_s, folder_path)

    if FolderTriageProposal.where(status: [ :proposed, :applied ]).exists?(folder_path: folder_path)
      Rails.logger.info("[FolderIngestJob] skip (déjà proposé/appliqué): #{folder_path}")
      return
    end

    files = files_in(abs)
    if files.empty?
      Rails.logger.info("[FolderIngestJob] aucun fichier à trier: #{folder_path}")
      return
    end

    build_cards(files)

    result = FolderTriageService.new(abs, files).call
    raise RateLimitError, result.error if rate_limited?(result.error)

    if result.error
      Rails.logger.error("[FolderIngestJob] triage échoué #{folder_path}: #{result.error}")
    else
      Rails.logger.info("[FolderIngestJob] proposé #{folder_path}: #{result.proposal.groups.size} groupes")
    end
  end

  private

  # Fichiers extraits, non triés, dont l'emplacement actif est DIRECTEMENT dans
  # ce dossier (pas dans un sous-dossier — chaque sous-dossier a son propre job).
  def files_in(abs_folder)
    CataloguedFile
      .extracted.where(triage_state: :pending)
      .joins(:file_locations).merge(FileLocation.active)
      .where("file_locations.path LIKE ?", "#{FolderTriageProposal.sanitize_sql_like(abs_folder)}/%")
      .where.not("file_locations.path LIKE ?", "#{FolderTriageProposal.sanitize_sql_like(abs_folder)}/%/%")
      .distinct
      .includes(:file_locations)
      .to_a
  end

  def build_cards(files)
    files.each do |cf|
      next if cf.ai_file_card_at.present?

      result = FileCardService.new(cf).call
      raise RateLimitError, result.error if rate_limited?(result.error)
    end
  end

  def rate_limited?(error)
    error.to_s.match?(RATE_LIMIT_RE)
  end
end
