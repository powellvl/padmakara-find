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

    # Par défaut, les propositions sont laissées en attente de review humaine
    # (/triage/folders). AUTO_APPLY=1 réapplique automatiquement (mode expérience).
    auto_apply = ENV["AUTO_APPLY"].present?

    by_folder.each do |folder, folder_files|
      rel = folder.delete_prefix(NasSource.root.to_s).delete_prefix("/")
      if FolderTriageProposal.where(status: [ :applied, :proposed ]).exists?(folder_path: rel)
        puts "[folder] skip (déjà proposé/appliqué): #{rel}"
        next
      end

      result = with_rate_limit_retry { FolderTriageService.new(folder, folder_files).call }
      if result.error || result.proposal.failed?
        puts "[folder] FAIL #{rel}: #{result.error || result.proposal.error}"
        next
      end

      unless auto_apply
        puts "[folder] proposé (à relire): #{rel} — #{result.proposal.groups.size} groupes"
        sleep 0.4
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

  desc "Enfile un FolderIngestJob par dossier contenant des fichiers extraits non triés. ENV: LIMIT (max dossiers)"
  task enqueue_all_folders: :environment do
    root = NasSource.root.to_s

    # Dossier immédiat de chaque fichier extrait non trié → ensemble de dossiers uniques.
    folders = CataloguedFile
      .extracted.where(triage_state: :pending)
      .joins(:file_locations).merge(FileLocation.active)
      .pluck("file_locations.path")
      .map { |p| File.dirname(p) }
      .uniq

    # On ne réenfile pas un dossier déjà proposé/appliqué.
    done = FolderTriageProposal.where(status: [ :proposed, :applied ]).pluck(:folder_path).to_set
    pending = folders.map { |abs| abs.delete_prefix(root).delete_prefix("/") }
                     .reject { |rel| done.include?(rel) }
    pending = pending.first(ENV["LIMIT"].to_i) if ENV["LIMIT"].present?

    pending.each { |rel| FolderIngestJob.perform_later(rel) }
    puts "[enqueue] #{pending.size} dossier(s) enfilé(s) (sur #{folders.size} au total, #{done.size} déjà traités)"
  end

  desc "Purge le catalogue et le régénère depuis les propositions déjà appliquées (aucun appel IA)"
  task regenerate_catalog: :environment do
    applied = FolderTriageProposal.applied.order(:created_at).to_a
    puts "AVANT : #{Text.count} texts / #{Version.count} versions / #{Deity.count} déités"
    puts "propositions à rejouer : #{applied.size}"

    ActiveRecord::Base.transaction do
      CataloguedFile.where.not(version_id: nil).update_all(version_id: nil)
      CataloguedFile.where(triage_state: :triaged).update_all(triage_state: 0)
      Version.delete_all
      Translation.delete_all
      ActiveRecord::Base.connection.execute(
        "DELETE FROM authors_texts; DELETE FROM deities_texts; DELETE FROM schools_texts; DELETE FROM tags_texts"
      )
      Text.delete_all
      Deity.where.missing(:texts).delete_all
      Author.where.missing(:texts).delete_all
      applied.each { |p| p.update_columns(status: FolderTriageProposal.statuses[:proposed]) }
    end

    ok = ko = 0
    applied.each do |p|
      res = FolderCatalogApplier.new(p.reload).call
      res.error ? (ko += 1) : (ok += 1)
      puts "  ÉCHEC #{p.folder_path}: #{res.error[0, 80]}" if res.error
    end

    puts "APRÈS : #{Text.count} texts / #{Translation.count} translations / #{Version.count} versions"
    puts "réappliquées : #{ok} OK, #{ko} échecs — #{Deity.count} déités, #{Author.count} auteurs"
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
