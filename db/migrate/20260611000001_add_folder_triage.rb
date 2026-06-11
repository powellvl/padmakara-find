class AddFolderTriage < ActiveRecord::Migration[8.0]
  def change
    # Per-file AI extraction card (vision for PDFs, text sample otherwise).
    # Produced before folder-level triage; consumed by FolderTriageService.
    add_column :catalogued_files, :ai_file_card, :jsonb
    add_column :catalogued_files, :ai_file_card_at, :datetime

    # One AI proposal per NAS folder: groups of files forming Text/Translation/Version units.
    create_table :folder_triage_proposals do |t|
      t.string  :folder_path, null: false
      t.integer :status, null: false, default: 0
      t.jsonb   :payload
      t.string  :model_used
      t.text    :error
      t.timestamps
    end
    add_index :folder_triage_proposals, :folder_path
    add_index :folder_triage_proposals, :status

    # Normalized Tibetan title — the cross-language join key for Texts.
    add_column :texts, :title_tibetan_normalized, :string
    add_index  :texts, :title_tibetan_normalized
  end
end
