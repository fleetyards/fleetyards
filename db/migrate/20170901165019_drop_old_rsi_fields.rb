class DropOldRsiFields < ActiveRecord::Migration[5.1]
  def up
    remove_column :users, :rsi_organization_url
    remove_column :users, :rsi_organization_handle
    remove_column :users, :rsi_organization_name
    remove_column :users, :rsi_profile_url
  end

  def down
    add_column :users, :rsi_organization_url, :string
    add_column :users, :rsi_organization_handle, :string
    add_column :users, :rsi_organization_name, :string
    add_column :users, :rsi_profile_url, :string
  end
end
