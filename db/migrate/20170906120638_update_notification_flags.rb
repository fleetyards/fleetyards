class UpdateNotificationFlags < ActiveRecord::Migration[5.1]
  def up
    remove_column :user_ships, :notify
    add_column :users, :sale_notify, :boolean, default: true
    add_column :user_ships, :sale_notify, :boolean, default: true
  end

  def down
    add_column :user_ships, :notify, :boolean, default: false
  end
end
