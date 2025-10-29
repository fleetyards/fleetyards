class AddDimensionFieldsToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :store_image_width, :integer
    add_column :models, :store_image_height, :integer
    add_column :models, :rsi_store_image_width, :integer
    add_column :models, :rsi_store_image_height, :integer
    add_column :model_upgrades, :store_image_width, :integer
    add_column :model_upgrades, :store_image_height, :integer
    add_column :components, :store_image_width, :integer
    add_column :components, :store_image_height, :integer
    add_column :equipment, :store_image_width, :integer
    add_column :equipment, :store_image_height, :integer
    add_column :model_module_packages, :store_image_width, :integer
    add_column :model_module_packages, :store_image_height, :integer
    add_column :model_modules, :store_image_width, :integer
    add_column :model_modules, :store_image_height, :integer
    add_column :model_paints, :store_image_width, :integer
    add_column :model_paints, :store_image_height, :integer
    add_column :model_paints, :rsi_store_image_width, :integer
    add_column :model_paints, :rsi_store_image_height, :integer
  end
end
