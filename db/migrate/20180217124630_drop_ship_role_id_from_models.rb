class DropShipRoleIdFromModels < ActiveRecord::Migration[5.1]
  def up
    remove_column :models, :ship_role_id
  end

  def down
    add_column :models, :ship_role_id, :uuid
  end
end
