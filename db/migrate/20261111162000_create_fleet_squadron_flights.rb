# frozen_string_literal: true

class CreateFleetSquadronFlights < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_squadron_flights, id: :uuid do |t|
      t.references :fleet_squadron, type: :uuid, null: false, index: true,
        foreign_key: {on_delete: :cascade}
      t.string :name, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    change_column_null :mission_teams, :mission_id, true

    add_reference :mission_teams, :fleet_squadron_flight,
      type: :uuid,
      foreign_key: {on_delete: :cascade},
      index: {unique: true}

    add_check_constraint :mission_teams,
      "num_nonnulls(mission_id, fleet_squadron_flight_id) = 1",
      name: "mission_teams_one_owner"

    add_reference :mission_teams, :source_flight,
      type: :uuid,
      foreign_key: {to_table: :fleet_squadron_flights, on_delete: :nullify},
      index: true

    add_reference :fleet_event_teams, :source_flight,
      type: :uuid,
      foreign_key: {to_table: :fleet_squadron_flights, on_delete: :nullify},
      index: true

    create_table :mission_slot_candidates, id: :uuid do |t|
      t.references :mission_slot, type: :uuid, null: false, index: false,
        foreign_key: {on_delete: :cascade}
      t.references :fleet_squadron_membership, type: :uuid, null: false, index: true,
        foreign_key: {on_delete: :cascade}
      t.references :vehicle, type: :uuid, null: true, index: true,
        foreign_key: {on_delete: :nullify}
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :mission_slot_candidates, %i[mission_slot_id fleet_squadron_membership_id],
      unique: true,
      name: "index_mission_slot_candidates_on_slot_and_membership"

    create_table :fleet_event_slot_candidates, id: :uuid do |t|
      t.references :fleet_event_slot, type: :uuid, null: false, index: false,
        foreign_key: {on_delete: :cascade}
      t.references :fleet_squadron_membership, type: :uuid, null: false, index: true,
        foreign_key: {on_delete: :cascade}
      t.references :vehicle, type: :uuid, null: true, index: true,
        foreign_key: {on_delete: :nullify}
      t.integer :position, null: false, default: 0
      t.datetime :passed_at
      t.timestamps
    end

    add_index :fleet_event_slot_candidates, %i[fleet_event_slot_id fleet_squadron_membership_id],
      unique: true,
      name: "index_fleet_event_slot_candidates_on_slot_and_membership"
  end
end
