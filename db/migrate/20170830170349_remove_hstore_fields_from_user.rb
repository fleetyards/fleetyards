class RemoveHstoreFieldsFromUser < ActiveRecord::Migration[5.1]
  def up
    remove_column :users, :settings
    remove_column :users, :profile
    remove_column :users, :provider
    remove_column :users, :uid
  end

  def down
    add_column :users, :settings, :hstore
    add_column :users, :profile, :hstore
    add_column :users, :provider, :string
    add_column :users, :uid, :string
  end
end
