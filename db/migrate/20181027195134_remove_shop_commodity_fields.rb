class RemoveShopCommodityFields < ActiveRecord::Migration[5.2]
  def up
    remove_column :shop_commodities, :name
    remove_column :shop_commodities, :description
  end

  def down
    add_column :shop_commodities, :name, :string
    add_column :shop_commodities, :description, :text
  end
end
