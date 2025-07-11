class CreateAuthorsTexts < ActiveRecord::Migration[8.0]
  def change
    create_table :authors_texts do |t|
      t.references :author, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :text, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.timestamps
    end

    add_index :authors_texts, [ :author_id, :text_id ], unique: true
  end
end
