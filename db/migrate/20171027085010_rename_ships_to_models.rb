class RenameShipsToModels < ActiveRecord::Migration[5.1]
  def change
    rename_table :ships, :models
    rename_column :user_ships, :ship_id, :model_id
    rename_column :vehicle_additions, :ship_id, :model_id
    rename_column :videos, :ship_id, :model_id
    rename_column :hardpoints, :ship_id, :model_id

    reversible do |change|
      change.up do
        Image.find_each do |image|
          image.gallery_type = 'Model'
          image.save
        end
      end
    end
  end
end
