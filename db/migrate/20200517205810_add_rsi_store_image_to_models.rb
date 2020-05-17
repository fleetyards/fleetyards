class AddRsiStoreImageToModels < ActiveRecord::Migration[6.0]
  def change
    add_column :models, :rsi_store_image, :string
  end
end
