class CreateTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :translations do |t|
      t.references :text, null: false, foreign_key: true
      t.string :language

      t.timestamps
    end
  end
end
