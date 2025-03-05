class AddPrimaryToAttachments < ActiveRecord::Migration[8.0]
  def change
    add_column :active_storage_attachments, :primary, :boolean, default: false
  end
end
