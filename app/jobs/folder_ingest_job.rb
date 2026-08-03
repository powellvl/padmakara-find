# Ingère un dossier du NAS en une unité : construit les cartes IA manquantes
# de ses fichiers, puis crée une FolderTriageProposal en attente de review.
#
# Un job = un dossier = une proposition. Pas d'ordonnancement inter-jobs : le
# dossier est autonome. Résumable (saute les cartes déjà faites et les dossiers
# déjà proposés/appliqués) et tolérant aux limites de débit (retry).
class FolderIngestJob < ApplicationJob
  queue_as :ingest

  # Erreurs transitoires du fournisseur IA (limite de débit OU coupure réseau) :
  # rejouées avec backoff plutôt que de produire une proposition manquante.
  class TransientError < StandardError; end
  RateLimitError = TransientError # compat rétro

  # Limite de débit (429) OU coupure/lenteur réseau (SSL, timeout, connexion).
  TRANSIENT_RE = /429|rate.?limit|too many requests|ssl_read|unexpected eof|timed?\s?out|timeout|connection (reset|refused|closed)|econnreset|broken pipe|end of file|eoferror/i

  retry_on TransientError, wait: :polynomially_longer, attempts: 6
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
    raise TransientError, result.error if transient?(result.error)

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
      raise TransientError, result.error if transient?(result.error)
    end
  end

  def transient?(error)
    error.to_s.match?(TRANSIENT_RE)
  end
end
