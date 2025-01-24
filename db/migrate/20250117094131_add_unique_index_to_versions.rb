class AddUniqueIndexToVersions < ActiveRecord::Migration[8.0]
  def change
    add_index :versions, [ :name, :translation_id ], unique: true
  end
end
