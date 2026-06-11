namespace :triage do
  # Folders (relative to NasSource.root) selected for the folder-triage experiment.
  # Chosen to cover: multi-language in one tree, same text in sibling folders,
  # multi-text catch-all folders, working files, noise, Spanish/archives.
  EXPERIMENT_FOLDERS = [
    "02-03 LIVRETS - PRIERES/02-03-03 Prières/Courtes prières à Tara 8 pages",
    "02-03 LIVRETS - PRIERES/02-03-01 Ngön Dro/007 L_Excellente Voie de la Libération - Laphur - Kangyour Rinpoche",
    "02-03 LIVRETS - PRIERES/02-03-01 Ngön Dro/008 The Excellent Path of Liberation - Lapur - Kangyour Rinpoche",
    "02-03 LIVRETS - PRIERES/02-03-03 Prières/Tenga Rinpoche",
    "02-03 LIVRETS - PRIERES/02-03-03 Prières/longue vie et prompt retour",
    "02-03 LIVRETS - PRIERES/02-03-03 Prières/Jedrung Rinpoche petite prière",
    "02-03 LIVRETS - PRIERES/02-03-02 Sadhanas/Vajrasattva",
    "02-03 LIVRETS - PRIERES/02-03-02 Sadhanas/Buddha Medecine",
    "02-03 LIVRETS - PRIERES/02-03-06 Recueil/Révision fich récup tib unicode",
    "02-03 LIVRETS - PRIERES/02-03-12 Archives/Anciennes Versions/Sadhana Shakyamuni Espagnol",
    "02-03 LIVRETS - PRIERES/02-03-07 Livrets/TRAVAIL EN COURS/Reine des prières d_aspiration à la bonne conduite",
    "02-03 LIVRETS - PRIERES/02-03-07 Livrets/TRAVAIL EN COURS/prière shabkar",
    "02-03 LIVRETS - PRIERES/02-03-03 Prières/Trulshik Rinpoché prière pour la promte renaissance/Livret Trulshik Rinpoche Anglais",
    "02-03 LIVRETS - PRIERES/02-03-03 Prières/Trulshik Rinpoché prière pour la promte renaissance/Espagnol",
    "02-03 LIVRETS - PRIERES/02-03-03 Prières/Trulshik Rinpoché prière pour la promte renaissance/19 sept/Prayer swift rebirth HHDL"
  ].freeze

  desc "Folder-triage experiment: build file cards then triage folder by folder. ENV: LIMIT (max files), CARDS_ONLY=1"
  task folder_experiment: :environment do
    roots = EXPERIMENT_FOLDERS.map { |f| File.join(NasSource.root.to_s, f) }

    locations = FileLocation.active.where(
      roots.map { "path LIKE ?" }.join(" OR "),
      *roots.map { |r| "#{r}/%" }
    ).includes(:catalogued_file).order(:path)

    files = locations.map(&:catalogued_file).uniq
    files = files.first(ENV["LIMIT"].to_i) if ENV["LIMIT"].present?
    puts "[experiment] #{files.size} files in #{roots.size} subset roots"

    # ── Phase A: per-file cards (idempotent: skips files already carded) ──────
    carded = failed = skipped = 0
    files.each_with_index do |cf, i|
      if cf.ai_file_card_at.present?
        skipped += 1
        next
      end

      result = with_rate_limit_retry { FileCardService.new(cf).call }
      path = cf.active_locations.first&.path.to_s.delete_prefix(NasSource.root.to_s)
      if result.card
        carded += 1
        puts "  [#{i + 1}/#{files.size}] card ok   #{path} (#{result.card["doc_kind"]})"
      else
        failed += 1
        puts "  [#{i + 1}/#{files.size}] card FAIL #{path}: #{result.error}"
      end
      sleep 0.4
    end
    puts "[phase A] cards: #{carded} new, #{skipped} existing, #{failed} failed"
    next if ENV["CARDS_ONLY"].present?

    # ── Phase B: folder-level triage + catalog application ────────────────────
    by_folder = files.group_by { |cf| File.dirname(cf.active_locations.first.path) }.sort

    by_folder.each do |folder, folder_files|
      rel = folder.delete_prefix(NasSource.root.to_s).delete_prefix("/")
      if FolderTriageProposal.applied.exists?(folder_path: rel)
        puts "[folder] skip (already applied): #{rel}"
        next
      end

      result = with_rate_limit_retry { FolderTriageService.new(folder, folder_files).call }
      if result.error || result.proposal.failed?
        puts "[folder] FAIL #{rel}: #{result.error || result.proposal.error}"
        next
      end

      applied = FolderCatalogApplier.new(result.proposal).call
      if applied.error
        puts "[folder] apply FAIL #{rel}: #{applied.error}"
      else
        puts "[folder] ok #{rel}: #{result.proposal.groups.size} groups → #{applied.texts.size} texts, #{applied.versions_count} versions"
      end
      sleep 0.4
    end

    puts "[done] texts=#{Text.count} translations=#{Translation.count} versions=#{Version.count} " \
         "triaged=#{CataloguedFile.triaged.count} proposals=#{FolderTriageProposal.group(:status).count}"
  end

  desc "Cross-language consolidation: merge Texts that are the same prayer. ENV: DRY_RUN=1"
  task consolidate: :environment do
    result = CatalogConsolidationService.new(dry_run: ENV["DRY_RUN"].present?).call

    label = ENV["DRY_RUN"].present? ? "fusion proposée" : "fusionné"
    result.merges.each { |m| puts "[#{label}] #{m}" }
    result.errors.each { |e| puts "[erreur] #{e}" }
    puts "[done] #{result.merges.size} fusions, #{result.errors.size} erreurs — texts=#{Text.count}"
  end

  def with_rate_limit_retry(max_retries: 4)
    attempts = 0
    loop do
      result = yield
      error = result.respond_to?(:error) ? result.error : nil
      return result unless error.to_s.match?(/429|rate.?limit/i) && attempts < max_retries

      attempts += 1
      wait = 5 * attempts
      puts "    rate-limited, retry #{attempts}/#{max_retries} in #{wait}s"
      sleep wait
    end
  end
end
