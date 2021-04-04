class AddIndexForFleetMemberships < ActiveRecord::Migration[6.1]
  def change
    add_index :fleet_memberships, [:user_id, :fleet_id], unique: true
  end
end
