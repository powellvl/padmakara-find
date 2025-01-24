class CreateSchoolsTexts < ActiveRecord::Migration[8.0]
  def change
    create_table :schools_texts do |t|
      t.references :school, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :text, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.timestamps
    end

    add_index :schools_texts, [ :school_id, :text_id ], unique: true
  end
end
