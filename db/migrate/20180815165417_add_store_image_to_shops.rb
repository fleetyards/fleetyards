class AddStoreImageToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :store_image, :string
  end
end
