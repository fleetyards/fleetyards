class AddRsiFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :rsi_organization_url, :string
    add_column :users, :rsi_organization_handle, :string
    add_column :users, :rsi_organization_name, :string
    add_column :users, :rsi_profile_url, :string
    add_column :users, :rsi_handle, :string
  end
end
