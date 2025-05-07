class UpdateTextCover
  def initialize(text)
    @text = text
  end

  def call
    # Cette méthode est appelée chaque fois qu'une version est publiée
    # ou qu'un fichier primary est modifié sur une version publiée

    # S'assurer d'avoir les données les plus récentes
    @text.reload

    # Pour toutes les traductions qui ont une version publiée,
    # s'assurer que la cover est générée
    @text.translations.each do |translation|
      version = translation.latest_published_version
      next unless version

      # Si la version n'a pas de cover mais a un fichier primaire, générer la cover
      if !version.cover.attached? && version.primary_file
        version.generate_cover
      end
    end

    true
  rescue => e
    Rails.logger.error("Erreur lors de la mise à jour des covers: #{e.message}")
    false
  end
end
