# Merges a duplicate Text into a canonical one: moves translations (and their
# versions, which keep their catalogued_files links), unions lookup
# associations, fills missing titles, then destroys the duplicate.
#
# Used by the cross-language consolidation pass: the same prayer often gets
# catalogued once per language folder with diverging Tibetan titles; merging
# turns those entries into one Text with one Translation per language.
class TextMergeService
  Result = Data.define(:text, :error)

  def initialize(keep, duplicate)
    @keep = keep
    @dup  = duplicate
  end

  def call
    return Result.new(text: @keep, error: "cannot merge a text into itself") if @keep.id == @dup.id

    ActiveRecord::Base.transaction do
      @dup.translations.each { |tr| move_translation(tr) }

      # Prefer plausible titles wherever they live: the "keep" side can carry a
      # hallucinated Tibetan/Wylie while the duplicate has the real one.
      if !TibetanText.plausible_tibetan?(@keep.title_tibetan) && TibetanText.plausible_tibetan?(@dup.title_tibetan)
        @keep.title_tibetan            = @dup.title_tibetan
        @keep.title_tibetan_normalized = @dup.title_tibetan_normalized
      end
      if !TibetanText.plausible_wylie?(@keep.title_wylie) && TibetanText.plausible_wylie?(@dup.title_wylie)
        @keep.title_wylie = @dup.title_wylie
      end
      @keep.title_phonetics ||= @dup.title_phonetics
      @keep.author_ids |= @dup.author_ids
      @keep.deity_ids  |= @dup.deity_ids
      @keep.school_ids |= @dup.school_ids
      @keep.save!

      @dup.reload.destroy!
    end

    Result.new(text: @keep, error: nil)
  rescue => e
    Rails.logger.error("[TextMergeService] merge #{@dup.id} → #{@keep.id} failed: #{e.message}")
    Result.new(text: nil, error: e.message)
  end

  private

  def move_translation(translation)
    existing = @keep.translations.find_by(language_id: translation.language_id)

    if existing
      # Same language on both sides: fold the duplicate's versions in.
      translation.versions.each do |version|
        if existing.versions.exists?(name: version.name)
          version.update!(name: "#{version.name} (#{@dup.id})")
        end
        version.update!(translation_id: existing.id)
      end
    else
      translation.update!(text_id: @keep.id)
    end
  end
end
