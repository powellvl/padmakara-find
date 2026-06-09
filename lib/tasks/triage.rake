namespace :triage do
  desc "Enqueue TriageFileJob for all extracted files that don't have a proposal yet"
  task enqueue_pending: :environment do
    scope = CataloguedFile
      .extracted
      .pending
      .where(
        "NOT EXISTS (SELECT 1 FROM ai_triage_proposals atp WHERE atp.catalogued_file_id = catalogued_files.id)"
      )

    total = scope.count
    puts "#{total} fichiers à triager"

    batch_size = (ENV["BATCH"] || total).to_i
    enqueued  = 0

    scope.limit(batch_size).find_each do |cf|
      TriageFileJob.perform_later(cf.id)
      enqueued += 1
      print "." if (enqueued % 100).zero?
    end

    puts "\n#{enqueued} jobs enqueués"
  end

  desc "Show triage queue status"
  task status: :environment do
    puts "--- Extraction ---"
    CataloguedFile.group(:extraction_status).count.each { |k, v| puts "  #{k}: #{v}" }
    puts "--- Triage proposals ---"
    AiTriageProposal.group(:status).count.each { |k, v| puts "  #{k}: #{v}" }
    pending_no_proposal = CataloguedFile
      .extracted.pending
      .where("NOT EXISTS (SELECT 1 FROM ai_triage_proposals atp WHERE atp.catalogued_file_id = catalogued_files.id)")
      .count
    puts "  sans proposal : #{pending_no_proposal}"
    puts "--- Textes catalogués ---"
    puts "  Texts: #{Text.count}"
    puts "  CataloguedFiles liés à une version: #{CataloguedFile.where.not(version_id: nil).count}"
  end
end
