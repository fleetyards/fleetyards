# frozen_string_literal: true

class CreateFleetSquadronShipRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_squadron_ship_requests, id: :uuid do |t|
      t.references :fleet_squadron_membership, type: :uuid, null: false, index: false,
        foreign_key: {on_delete: :cascade}
      t.references :vehicle, type: :uuid, null: false, index: true,
        foreign_key: {on_delete: :cascade}
      t.references :requested_by, type: :uuid, null: true, index: true,
        foreign_key: {to_table: :fleet_memberships, on_delete: :nullify}
      t.timestamps
    end

    add_index :fleet_squadron_ship_requests, %i[fleet_squadron_membership_id vehicle_id],
      unique: true,
      name: "index_squadron_ship_requests_on_membership_and_vehicle"
  end
end
