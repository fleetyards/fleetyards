class AddBasedOnVehicleIdsToHangarPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :hangar_plans, :based_on_vehicle_ids, :uuid, array: true
  end
end
