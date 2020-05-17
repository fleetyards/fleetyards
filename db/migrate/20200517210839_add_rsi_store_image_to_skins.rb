class AddRsiStoreImageToSkins < ActiveRecord::Migration[6.0]
  def change
    add_column :model_skins, :rsi_store_image, :string
  end
end
