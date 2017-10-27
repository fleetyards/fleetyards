class RenameVehicleAdditionsToModelAdditions < ActiveRecord::Migration[5.1]
  def change
    rename_table :vehicle_additions, :model_additions
  end
end
