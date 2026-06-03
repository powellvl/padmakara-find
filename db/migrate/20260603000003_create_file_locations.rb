class CreateFileLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :file_locations do |t|
      t.references :catalogued_file, null: false, foreign_key: true

      # Absolute path as seen from the app server (NAS mount point included).
      t.text :path, null: false

      # Stat data captured at scan time — used to skip re-hashing unchanged files.
      t.datetime :mtime, null: false

      t.datetime :last_seen_at, null: false

      # Non-null when the path disappeared from the NAS between two scans.
      # The catalogued_file row is never deleted — we keep the content record forever.
      t.datetime :missing_since

      t.timestamps
    end

    add_index :file_locations, :path, unique: true
    add_index :file_locations, :last_seen_at
    add_index :file_locations, :missing_since
  end
end
