class AddStateFieldsToFleetMemberships < ActiveRecord::Migration[6.1]
  def change
    add_column :fleet_memberships, :aasm_state, :string
    add_column :fleet_memberships, :invited_at, :datetime
    add_column :fleet_memberships, :requested_at, :datetime
    remove_column :fleet_memberships, :approved, :boolean
  end
end
