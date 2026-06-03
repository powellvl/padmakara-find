class CreateCataloguedFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :catalogued_files do |t|
      # Content-addressed identity: SHA-256 hex digest of the file bytes.
      # Two files at different paths with the same checksum → one row here.
      t.string :sha256_checksum, null: false
      t.bigint :byte_size, null: false
      t.string :content_type, null: false, default: "application/octet-stream"

      # Triage lifecycle: pending until an operator links this file to a Version.
      t.integer :triage_state, null: false, default: 0

      t.datetime :first_seen_at, null: false
      t.datetime :last_scan_at,  null: false

      t.timestamps
    end

    add_index :catalogued_files, :sha256_checksum, unique: true
    add_index :catalogued_files, :content_type
    add_index :catalogued_files, :triage_state
  end
end
