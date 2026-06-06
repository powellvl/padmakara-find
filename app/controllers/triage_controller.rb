class TriageController < ApplicationController
  before_action :set_proposal, only: %i[show accept reject skip rerun]

  # GET /triage — queue of files with pending AI proposals
  def index
    @pending  = AiTriageProposal.awaiting_review
                                .for_prayer_texts
                                .includes(catalogued_file: :file_locations)
                                .order(created_at: :asc)
                                .limit(50)

    @stats = {
      pending:  AiTriageProposal.pending_review.count,
      accepted: AiTriageProposal.accepted.count,
      skipped:  AiTriageProposal.skipped.count + AiTriageProposal.rejected.count
    }

    @awaiting_triage = CataloguedFile
      .extracted
      .pending
      .where("NOT EXISTS (SELECT 1 FROM ai_triage_proposals atp WHERE atp.catalogued_file_id = catalogued_files.id)")
      .count
  end

  # GET /triage/:id — review a single proposal
  def show
    @cf           = @proposal.catalogued_file
    @location     = @cf.active_locations.first
    @near_dupes   = NearDuplicateFinder.new(@cf).call

    @languages = Language.all.order(:name)
    @deities   = Deity.all.order(:name_english)
    @schools   = School.all.order(:name)
    @authors   = Author.all.order(:name_english)
  end

  # POST /triage/:id/accept — human confirms/edits proposal → creates catalog entries
  def accept
    cf = @proposal.catalogued_file

    ActiveRecord::Base.transaction do
      language    = Language.find_or_create_by!(name: accept_params[:language]) if accept_params[:language].present?
      text        = find_or_create_text(accept_params, language)
      translation = find_or_create_translation(text, language)
      version     = find_or_create_version(translation, cf)

      cf.update!(version_id: version.id, triage_state: :triaged)
      @proposal.update!(status: :accepted)
    end

    redirect_to triage_index_path, notice: "Fichier catalogué avec succès."
  rescue => e
    redirect_to triage_path(@proposal), alert: "Erreur : #{e.message}"
  end

  # POST /triage/:id/skip
  def skip
    @proposal.update!(status: :skipped)
    redirect_to triage_index_path, notice: "Fichier ignoré."
  end

  # POST /triage/:id/reject
  def reject
    @proposal.update!(status: :rejected)
    redirect_to triage_index_path, notice: "Proposition rejetée."
  end

  # POST /triage/:id/rerun — re-run with the strong model
  def rerun
    TriageFileJob.perform_later(@proposal.catalogued_file_id, force_strong_model: true)
    @proposal.update!(status: :skipped)  # archive the current proposal
    redirect_to triage_index_path, notice: "Nouvelle analyse avec le modèle fort lancée."
  end

  private

  def set_proposal
    @proposal = AiTriageProposal.find(params[:id])
  end

  def accept_params
    params.require(:proposal).permit(
      :title_tibetan, :title_wylie, :title_phonetic,
      :language, :version_name,
      deity_ids: [], school_ids: [], author_ids: []
    )
  end

  def find_or_create_text(p, language)
    # Try to find an existing text by Tibetan title to avoid duplicates.
    text = Text.find_by(title_tibetan: p[:title_tibetan]) if p[:title_tibetan].present?

    unless text
      text = Text.new(
        title_tibetan:   p[:title_tibetan],
        title_wylie:     p[:title_wylie],
        title_phonetics: p[:title_phonetic]
      )
      text.deity_ids  = Array(p[:deity_ids]).reject(&:blank?)
      text.school_ids = Array(p[:school_ids]).reject(&:blank?)
      text.author_ids = Array(p[:author_ids]).reject(&:blank?)
      text.save!
    end

    text
  end

  def find_or_create_translation(text, language)
    return text.translations.first_or_create!(language: language) if language

    text.translations.first || text.translations.create!(language: Language.first)
  end

  def find_or_create_version(translation, cf)
    name = accept_params[:version_name].presence ||
           cf.active_locations.first&.filename ||
           "Version 1"

    translation.versions.find_or_create_by!(name: name) do |v|
      v.status = :draft
    end
  end
end
