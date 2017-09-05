class AddNotifyFlagToUserShips < ActiveRecord::Migration[5.1]
  def change
    add_column :user_ships, :notify, :boolean, default: false
  end
end
