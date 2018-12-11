class AddSellingFlagToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :selling, :boolean, default: false
  end
end
