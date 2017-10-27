class DropShipRolesTable < ActiveRecord::Migration[5.1]
  def up
    drop_table :ship_roles if ActiveRecord::Base.connection.table_exists? 'ship_roles'
  end

  def down
  end
end
