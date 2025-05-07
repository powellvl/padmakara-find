class AddTitleWylieToText < ActiveRecord::Migration[8.0]
  def change
    add_column :texts, :title_wylie, :string
  end
end
