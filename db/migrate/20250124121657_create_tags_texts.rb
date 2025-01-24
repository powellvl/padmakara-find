class CreateTagsTexts < ActiveRecord::Migration[8.0]
  def change
    create_table :tags_texts do |t|
      t.references :tag, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :text, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.timestamps
    end

    add_index :tags_texts, [ :tag_id, :text_id ], unique: true
  end
end
