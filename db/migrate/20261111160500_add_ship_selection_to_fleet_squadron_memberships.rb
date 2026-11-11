# frozen_string_literal: true

class AddShipSelectionToFleetSquadronMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_squadron_memberships, :ships_filter, :integer, null: false, default: 0

    add_reference :fleet_squadron_memberships, :hangar_group,
      type: :uuid,
      foreign_key: {on_delete: :nullify},
      index: true

    create_table :fleet_squadron_membership_vehicles, id: :uuid do |t|
      t.references :fleet_squadron_membership, type: :uuid, null: false, index: false,
        foreign_key: {on_delete: :cascade}
      t.references :vehicle, type: :uuid, null: false, index: true,
        foreign_key: {on_delete: :cascade}
      t.timestamps
    end

    add_index :fleet_squadron_membership_vehicles, %i[fleet_squadron_membership_id vehicle_id],
      unique: true,
      name: "index_squadron_membership_vehicles_on_membership_and_vehicle"
  end
end
