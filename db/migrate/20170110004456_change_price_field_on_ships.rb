class ChangePriceFieldOnShips < ActiveRecord::Migration
  def up
    remove_column :ships, :price
    add_column :ships, :price, :decimal, precision: 10, scale: 2, default: "0.0", null: false
  end

  def down
    remove_column :ships, :price
    add_column :ships, :price, :text
  end
end
