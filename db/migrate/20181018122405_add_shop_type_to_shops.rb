class AddShopTypeToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :shop_type, :integer
  end
end
