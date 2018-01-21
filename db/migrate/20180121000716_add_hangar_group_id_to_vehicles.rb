class AddHangarGroupIdToVehicles < ActiveRecord::Migration[5.1]
  def change
    add_column :vehicles, :hangar_group_id, :uuid
  end
end
