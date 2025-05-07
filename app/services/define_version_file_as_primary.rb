class DefineVersionFileAsPrimary
  def initialize(version, attachment)
    @version = version
    @attachment = attachment
  end

  def call
    ActiveRecord::Base.transaction do
      # Réinitialiser tous les fichiers comme non-prioritaires
      @version.files_attachments.update_all(primary: false)
      # Définir le nouveau fichier prioritaire
      @attachment.update!(primary: true)

      # Générer la cover si c'est un PDF
      ExtractPdfCover.new(@version).call
    end

    true
  rescue => e
    Rails.logger.error("Erreur lors de la définition du fichier primaire: #{e.message}")
    false
  end
end
