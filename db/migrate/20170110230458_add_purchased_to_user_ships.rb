class AddPurchasedToUserShips < ActiveRecord::Migration
  def change
    add_column :user_ships, :purchased, :boolean, default: false
  end
end
