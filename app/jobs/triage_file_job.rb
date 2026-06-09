class TriageFileJob < ApplicationJob
  queue_as :default

  def perform(catalogued_file_id, force_strong_model: false)
    cf = CataloguedFile.find_by(id: catalogued_file_id)
    return unless cf
    return unless cf.extracted?         # only triage files we could read
    return if cf.triaged?               # already linked to a version

    triage = AiTriageService.new(cf, force_strong_model: force_strong_model).call

    if triage.error
      Rails.logger.error("[TriageFileJob] AiTriageService error for #{cf.id}: #{triage.error}")
      return
    end

    auto = AutoTriageService.new(triage.proposal).call
    if auto.error
      Rails.logger.error("[TriageFileJob] AutoTriageService error for #{cf.id}: #{auto.error}")
    end
  end
end
