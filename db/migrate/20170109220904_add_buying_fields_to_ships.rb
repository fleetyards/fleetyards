class AddBuyingFieldsToShips < ActiveRecord::Migration[5.1]
  def change
    add_column :ships, :price, :text
    add_column :ships, :on_sale, :boolean, default: false
  end
end
