# Décide si un Text doit être masqué par défaut de la bibliothèque : c'est le
# cas quand TOUS ses fichiers proviennent de dossiers d'archive/travail
# (versions obsolètes, vieux ordis, corbeilles). Rien n'est supprimé — juste
# filtré, avec un bouton pour tout afficher.
module TextRelevance
  # Marqueurs de dossiers non pertinents (fr/en/es/pt), insensibles à la casse.
  ARCHIVE_RE = /
    archives? | anciennes?\s+versions? | \bold\b | obsol[eè]te | obsoleto | obsoletas? |
    copie\s+ancien\s+ordi | moved\s+sur\s+e | a\s+classer | corbeille | papelera |
    a\s+effacer | \bvieux\b | backup | brouillons? | versiones?\s+antiguas?
  /xi

  module_function

  # true si le texte n'a que des fichiers d'archive (ou aucun fichier localisé).
  def archive_only?(text)
    paths = active_paths(text)
    paths.present? && paths.all? { |p| p.match?(ARCHIVE_RE) }
  end

  # Recalcule et persiste le drapeau sur un texte.
  def refresh!(text)
    text.update_column(:archived, archive_only?(text))
  end

  # Recalcule sur tout le catalogue. Retourne le nombre de textes archivés.
  def refresh_all!
    Text.find_each { |t| refresh!(t) }
    Text.where(archived: true).count
  end

  def active_paths(text)
    CataloguedFile
      .joins(:file_locations)
      .where(version_id: Version.where(translation_id: text.translation_ids))
      .where(file_locations: { missing_since: nil })
      .pluck("file_locations.path")
  end
end
