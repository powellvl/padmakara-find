class RenameEmailAddressToEmail < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :email_address, :email
    rename_index :users, :index_users_on_email_address, :index_users_on_email
  end
end
