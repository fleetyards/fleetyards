class AddVerifiedToFleetMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_memberships, :verified, :boolean, default: false, null: false
  end
end
