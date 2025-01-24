class CreateVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :versions do |t|
      t.references :translation, null: false, foreign_key: true
      t.string :name
      t.integer :status

      t.timestamps
    end
  end
end
