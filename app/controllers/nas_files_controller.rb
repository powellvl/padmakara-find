# Streams a CataloguedFile's content from the NAS through the app.
# Read-only bridge: the NAS is the single source of truth; the app never
# exposes the mount directly.
class NasFilesController < ApplicationController
  def show
    catalogued_file = CataloguedFile.find(params[:id])
    location = catalogued_file.active_locations.order(:path).first

    unless location && File.file?(location.path) && within_nas?(location.path)
      redirect_back fallback_location: root_path,
                    alert: "Fichier introuvable sur le NAS (déplacé ou volume non monté)." and return
    end

    send_file location.path,
              filename:    location.filename,
              type:        catalogued_file.content_type.presence || "application/octet-stream",
              disposition: params[:download].present? ? "attachment" : "inline"
  end

  private

  # Guards against any path that escaped the NAS root (symlinks, bad data).
  def within_nas?(path)
    File.realpath(path).start_with?(File.realpath(NasSource.root.to_s) + File::SEPARATOR)
  rescue Errno::ENOENT
    false
  end
end
