class AddNormalizedLoginFieldsToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_users, :normalized_username, :string
    add_column :admin_users, :normalized_email, :string
  end
end
