class CreateTexts < ActiveRecord::Migration[8.0]
  def change
    create_table :texts do |t|
      t.string :title_tibetan
      t.string :title_phonetics
      t.text :notes

      t.timestamps
    end
  end
end
