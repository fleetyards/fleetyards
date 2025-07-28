class AddAccessFieldsToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_users, :super_admin, :boolean, default: false
    add_column :admin_users, :resource_access, :string
  end
end
