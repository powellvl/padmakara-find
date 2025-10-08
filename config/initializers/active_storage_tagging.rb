# Extension pour ajouter le support des tags aux attachments Active Storage
Rails.application.config.to_prepare do
  ActiveStorage::Attachment.class_eval do
    include Taggable

    # Méthode pour obtenir le nom de fichier de façon sécurisée
    def display_name
      filename.to_s
    end

    # Méthode pour obtenir l'extension du fichier
    def file_extension
      return "" unless filename.present?
      File.extname(filename.to_s).downcase
    end

    # Méthode pour vérifier si le fichier est une image
    def image?
      return false unless content_type.present?
      content_type.start_with?("image/")
    end

    # Méthode pour vérifier si le fichier est un PDF
    def pdf?
      content_type == "application/pdf"
    end

    # Méthode pour vérifier si le fichier est un document Word
    def word_document?
      return false unless content_type.present?
      content_type.in?([
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ])
    end
  end
end
