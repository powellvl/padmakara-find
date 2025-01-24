class CreateDeities < ActiveRecord::Migration[8.0]
  def change
    create_table :deities do |t|
      t.string :name_tibetan
      t.string :name_sanskrit
      t.string :name_english

      t.timestamps
    end
  end
end
