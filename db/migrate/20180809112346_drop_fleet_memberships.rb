class DropFleetMemberships < ActiveRecord::Migration[5.2]
  def up
    drop_table :fleet_memberships if ActiveRecord::Base.connection.table_exists? 'fleet_memberships'
  end

  def down
  end
end
