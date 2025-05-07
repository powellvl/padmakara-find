class ExtractPdfCover
  require "tempfile"

  def initialize(version)
    @version = version
  end

  def call
    return nil unless @version.primary_file.present? && pdf?

    pdf_file = nil
    img_file = nil

    begin
      # Télécharger le PDF
      pdf_data = @version.primary_file.download

      # Créer un fichier temporaire pour le PDF
      pdf_file = Tempfile.new([ "input", ".pdf" ])
      pdf_file.binmode
      pdf_file.write(pdf_data)
      pdf_file.close

      # Créer un fichier temporaire pour l'image
      img_file = Tempfile.new([ "output", ".jpg" ])
      img_file.close

      # Exécuter la commande convert en shell
      command = "convert -density 300 \"#{pdf_file.path}[0]\" -quality 90 \"#{img_file.path}\""
      puts "Exécution de la commande: #{command}"

      if system(command)
        # Attacher l'image comme cover
        @version.cover.attach(
          io: File.open(img_file.path),
          filename: "cover-#{@version.id}.jpg",
          content_type: "image/jpeg"
        )
        true
      else
        puts "Échec de la commande convert"
        false
      end
    rescue => e
      puts "ERREUR: #{e.message}"
      puts e.backtrace.join("\n")
      false
    ensure
      pdf_file.unlink if pdf_file && File.exist?(pdf_file.path)
      img_file.unlink if img_file && File.exist?(img_file.path)
    end
  end

  private

  def pdf?
    @version.primary_file.content_type == "application/pdf"
  end
end
