class AddStoreImagesUpdatedAtToModels < ActiveRecord::Migration[5.1]
  def change
    add_column :models, :store_images_updated_at, :datetime
  end
end
