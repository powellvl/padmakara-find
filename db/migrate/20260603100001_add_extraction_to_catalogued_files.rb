class AddExtractionToCataloguedFiles < ActiveRecord::Migration[8.0]
  def up
    add_column :catalogued_files, :extracted_text,    :text
    add_column :catalogued_files, :extraction_status, :integer, null: false, default: 0
    add_column :catalogued_files, :content_tsvector,  :tsvector

    add_index :catalogued_files, :extraction_status
    # GIN index for fast tsvector full-text queries
    add_index :catalogued_files, :content_tsvector, using: :gin,
              name: "index_catalogued_files_on_content_tsvector"
    # pg_trgm index on extracted_text for similarity / ILIKE queries
    execute <<~SQL
      CREATE INDEX index_catalogued_files_on_extracted_text_trgm
        ON catalogued_files
        USING gin (extracted_text gin_trgm_ops)
    SQL
  end

  def down
    remove_index :catalogued_files, name: "index_catalogued_files_on_extracted_text_trgm"
    remove_index :catalogued_files, name: "index_catalogued_files_on_content_tsvector"
    remove_index :catalogued_files, :extraction_status
    remove_column :catalogued_files, :content_tsvector
    remove_column :catalogued_files, :extraction_status
    remove_column :catalogued_files, :extracted_text
  end
end
