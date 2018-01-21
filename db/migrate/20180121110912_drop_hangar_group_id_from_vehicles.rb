class DropHangarGroupIdFromVehicles < ActiveRecord::Migration[5.1]
  def up
    remove_column :vehicles, :hangar_group_id
  end

  def down
    add_column :vehicles, :hangar_group_id, :uuid
  end
end
