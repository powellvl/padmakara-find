class CreateDeitiesTexts < ActiveRecord::Migration[8.0]
  def change
    create_table :deities_texts do |t|
      t.references :deity, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :text, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.timestamps
    end

    add_index :deities_texts, [ :deity_id, :text_id ], unique: true
  end
end
