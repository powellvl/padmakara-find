# Finds CataloguedFiles whose extracted_text is similar to a given file's text,
# using PostgreSQL pg_trgm similarity scoring.
#
# This is a pragmatic Phase 03 approach — not semantic embeddings, but sufficient
# to surface near-identical texts (same prayer, different file format or minor edits).
# See DECISIONS.md for the rationale and upgrade path.
class NearDuplicateFinder
  DEFAULT_THRESHOLD = 0.35
  DEFAULT_LIMIT     = 5

  def initialize(catalogued_file, threshold: DEFAULT_THRESHOLD, limit: DEFAULT_LIMIT)
    @cf        = catalogued_file
    @threshold = threshold
    @limit     = limit
  end

  def call
    return [] if @cf.extracted_text.blank?

    CataloguedFile
      .where.not(id: @cf.id)
      .where.not(extracted_text: nil)
      .where("similarity(extracted_text, ?) > ?", @cf.extracted_text.first(2_000), @threshold)
      .select("catalogued_files.*, similarity(extracted_text, #{CataloguedFile.sanitize_sql_array([ "?", @cf.extracted_text.first(2_000) ])}) AS similarity_score")
      .order("similarity_score DESC")
      .limit(@limit)
  end
end
