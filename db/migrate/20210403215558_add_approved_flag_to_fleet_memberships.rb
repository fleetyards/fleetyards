class AddApprovedFlagToFleetMemberships < ActiveRecord::Migration[6.1]
  def change
    add_column :fleet_memberships, :approved, :boolean, default: true
  end
end
