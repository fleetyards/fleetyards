class AddPurchasedToUserShips < ActiveRecord::Migration[5.1]
  def change
    add_column :user_ships, :purchased, :boolean, default: false
  end
end
