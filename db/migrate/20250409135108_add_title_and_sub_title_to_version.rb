class AddTitleAndSubTitleToVersion < ActiveRecord::Migration[8.0]
  def change
    add_column :versions, :title, :string
    add_column :versions, :subtitle, :string
  end
end
