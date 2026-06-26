class ExtractTextJob < ApplicationJob
  queue_as :default

  def perform(catalogued_file_id)
    cf = CataloguedFile.find_by(id: catalogued_file_id)
    return unless cf

    location = cf.active_locations.first
    unless location
      cf.update!(extraction_status: :extraction_failed)
      Rails.logger.warn("[ExtractTextJob] no active location for CataloguedFile #{cf.id}")
      return
    end

    result = TextExtractor.new(location.path, cf.content_type).call

    case result.status
    when :extracted
      cf.update!(extracted_text: result.text, extraction_status: :extracted)
      cf.update_tsvector!
      # Le triage est désormais déclenché par dossier (FolderIngestJob), plus
      # par fichier. L'ancien TriageFileJob (1 texte par fichier) est déprécié.
    when :unsupported_format
      cf.update!(extraction_status: :unsupported_format)
    when :extraction_failed
      cf.update!(extraction_status: :extraction_failed)
      Rails.logger.error("[ExtractTextJob] extraction failed for #{location.path}: #{result.error}")
    end
  end
end
