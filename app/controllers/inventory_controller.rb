class InventoryController < ApplicationController
  def index
    active_locations = FileLocation.active

    @total_unique_files   = CataloguedFile.count
    @total_active_locs    = active_locations.count
    @total_missing_locs   = FileLocation.missing.count
    @total_bytes          = CataloguedFile.sum(:byte_size)

    @counts_by_format = CataloguedFile
      .joins(:file_locations)
      .merge(FileLocation.active)
      .group(:content_type)
      .count
      .sort_by { |_, n| -n }

    @counts_by_top_folder = active_locations
      .group_by(&:top_folder)
      .transform_values(&:count)
      .sort_by { |_, n| -n }

    @exact_duplicates = CataloguedFile
      .with_multiple_active_locations
      .includes(:file_locations)
  end

  def trigger_scan
    NasScanJob.perform_later
    redirect_to inventory_path, notice: "Scan lancé en arrière-plan."
  end
end
