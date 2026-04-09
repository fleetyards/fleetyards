class RemoveRoleFromFleetMemberships < ActiveRecord::Migration[8.1]
  def change
    remove_column :fleet_memberships, :role, :integer
  end
end
