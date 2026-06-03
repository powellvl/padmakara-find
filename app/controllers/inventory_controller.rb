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

    # Two-step: the GROUP BY scope returns only IDs; we then load the full records
    # with their locations in a separate query to avoid a PG GROUP BY conflict.
    duplicate_ids = CataloguedFile.with_multiple_active_locations.pluck(:id)
    @exact_duplicates = CataloguedFile.where(id: duplicate_ids).includes(:file_locations)

    @extraction_counts = CataloguedFile.group(:extraction_status).count
  end

  def trigger_scan
    NasScanJob.perform_later
    redirect_to inventory_path, notice: "Scan lancé en arrière-plan."
  end
end
