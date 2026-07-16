require "open3"

# Rend la 1re page d'un PDF du NAS en vignette JPEG, mise en cache sur disque.
# Sert la review humaine : afficher la preuve (la couverture) à côté du titre
# proposé par l'IA, pour juger sans lire le tibétain ni ouvrir le fichier.
class PdfPagePreview
  WIDTH     = 420
  CACHE_DIR = Rails.root.join("tmp", "previews")

  def initialize(catalogued_file)
    @cf = catalogued_file
  end

  # Retourne les octets JPEG, ou nil si le fichier n'est pas un PDF lisible.
  def call
    cached = CACHE_DIR.join("#{@cf.sha256_checksum}.jpg")
    return cached.binread if cached.exist?

    location = pdf_location
    return nil unless location

    FileUtils.mkdir_p(CACHE_DIR)
    Dir.mktmpdir do |dir|
      prefix = File.join(dir, "p")
      _out, _err, status = Open3.capture3(
        "pdftoppm", "-jpeg", "-r", "110", "-scale-to-x", WIDTH.to_s, "-scale-to-y", "-1",
        "-f", "1", "-l", "1", location.path, prefix
      )
      jpg = Dir.glob("#{prefix}*.jpg").first
      return nil unless status.success? && jpg

      FileUtils.cp(jpg, cached)
      File.binread(cached)
    end
  rescue => e
    Rails.logger.warn("[PdfPagePreview] #{@cf.id}: #{e.message}")
    nil
  end

  private

  def pdf_location
    @cf.active_locations.find { |loc| loc.extension == ".pdf" && File.file?(loc.path) }
  end
end
