module FolderTriageHelper
  # Fichier le plus représentatif d'un groupe pour l'aperçu visuel : le premier
  # PDF joué comme "version" (le document publiable), à défaut n'importe quel
  # PDF du groupe. Les non-PDF n'ont pas d'aperçu.
  def group_preview_file(group, files_by_id)
    entries = Array(group["files"])
    ordered = entries.sort_by { |f| f["role"] == "version" ? 0 : 1 }

    ordered.each do |f|
      cf = files_by_id[f["id"]]
      next unless cf

      return cf if cf.active_locations.any? { |loc| loc.extension == ".pdf" }
    end
    nil
  end
end
