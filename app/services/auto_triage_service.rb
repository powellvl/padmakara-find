# Accepts an AiTriageProposal automatically, creating Text/Translation/Version records
# without human review.
#
# Rules:
#   is_prayer_text: false  → rejected (no catalog entry created)
#   is_prayer_text: true   → accepted regardless of confidence level
#                            (low confidence texts get a draft Version — same as high confidence)
#
# Deduplication: texts are matched by title_tibetan (if present) or title_phonetics.
# Multiple versions of the same text (different files) are grouped under one Text record.
class AutoTriageService
  Result = Data.define(:text, :version, :skipped, :error)

  def initialize(proposal)
    @proposal = proposal
    @cf       = proposal.catalogued_file
  end

  def call
    unless @proposal.is_prayer_text?
      @proposal.update!(status: :rejected)
      return Result.new(text: nil, version: nil, skipped: true, error: nil)
    end

    ActiveRecord::Base.transaction do
      language    = find_or_create_language
      text        = find_or_create_text(language)
      translation = find_or_create_translation(text, language)
      version     = find_or_create_version(translation)

      @cf.update!(version_id: version.id, triage_state: :triaged)
      @proposal.update!(status: :accepted)

      Result.new(text: text, version: version, skipped: false, error: nil)
    end
  rescue => e
    Rails.logger.error("[AutoTriageService] failed for proposal #{@proposal.id}: #{e.message}")
    Result.new(text: nil, version: nil, skipped: false, error: e.message)
  end

  private

  def find_or_create_language
    name = @proposal.proposed_language.presence || "Unknown"
    Language.find_or_create_by!(name: name)
  end

  def find_or_create_text(language)
    tib_title = @proposal.proposed_title_tibetan.presence
    pho_title = @proposal.proposed_title_phonetic.presence
    wylie     = @proposal.proposed_title_wylie.presence

    # Deduplication: match on Tibetan title first, then phonetic
    existing = Text.find_by(title_tibetan: tib_title) if tib_title
    existing ||= Text.find_by(title_phonetics: pho_title) if pho_title

    return existing if existing

    # Fallback to filename when the AI couldn't identify any title
    fallback = @cf.active_locations.first&.filename&.sub(/\.[^.]+$/, "")
    pho_title ||= fallback

    text = Text.new(
      title_tibetan:   tib_title,
      title_phonetics: pho_title,
      title_wylie:     wylie
    )
    text.deity_ids  = matched_ids(Deity, :name_english, @proposal.proposed_deity_names)
    text.school_ids = matched_ids(School, :name, @proposal.proposed_school_names)
    text.author_ids = matched_ids(Author, :name_english, @proposal.proposed_author_names)
    text.save!
    text
  end

  def find_or_create_translation(text, language)
    text.translations.find_or_create_by!(language: language)
  end

  def find_or_create_version(translation)
    name = @cf.active_locations.first&.filename || "Version 1"

    translation.versions.find_or_create_by!(name: name) do |v|
      v.status = :draft
    end
  end

  # Returns IDs of records whose name field fuzzy-matches any of the AI-proposed names.
  def matched_ids(klass, name_field, proposed_names)
    return [] if proposed_names.blank?

    klass.all.filter_map do |record|
      record_name = record.public_send(name_field).to_s.downcase
      proposed_names.any? { |n|
        n = n.to_s.downcase
        record_name.include?(n) || n.include?(record_name)
      } ? record.id : nil
    end
  end
end
