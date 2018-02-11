class AddFieldsToFleetMemberships < ActiveRecord::Migration[5.1]
  def change
    add_column :fleet_memberships, :avatar, :string
    add_column :fleet_memberships, :handle, :string
    add_column :fleet_memberships, :rank, :string
    add_column :fleet_memberships, :name, :string
    remove_column :fleet_memberships, :admin, :boolean, default: false, null: false
    remove_column :fleet_memberships, :approved, :boolean, default: false, null: false

    FleetMembership.destroy_all
  end
end
