# frozen_string_literal: true

class ExtendFleetEventSignups < ActiveRecord::Migration[8.1]
  def up
    add_reference :fleet_event_signups, :fleet_event, type: :uuid, foreign_key: true, null: true

    execute <<~SQL
      UPDATE fleet_event_signups s
      SET fleet_event_id = sub.event_id
      FROM (
        SELECT slots.id AS slot_id,
          CASE
            WHEN slots.slottable_type = 'FleetEventTeam' THEN teams.fleet_event_id
            WHEN slots.slottable_type = 'FleetEventShip' THEN team_for_ship.fleet_event_id
          END AS event_id
        FROM fleet_event_slots slots
        LEFT JOIN fleet_event_teams teams
          ON slots.slottable_type = 'FleetEventTeam' AND teams.id = slots.slottable_id
        LEFT JOIN fleet_event_ships ships
          ON slots.slottable_type = 'FleetEventShip' AND ships.id = slots.slottable_id
        LEFT JOIN fleet_event_teams team_for_ship
          ON slots.slottable_type = 'FleetEventShip' AND team_for_ship.id = ships.fleet_event_team_id
      ) sub
      WHERE s.fleet_event_slot_id = sub.slot_id;
    SQL

    change_column_null :fleet_event_signups, :fleet_event_id, false
    change_column_null :fleet_event_signups, :fleet_event_slot_id, true

    if index_exists?(:fleet_event_signups, [:fleet_event_slot_id, :fleet_membership_id], name: "index_fleet_event_signups_unique_active")
      remove_index :fleet_event_signups, name: "index_fleet_event_signups_unique_active"
    end

    add_index :fleet_event_signups, [:fleet_event_id, :fleet_membership_id],
      unique: true,
      where: "status <> 'withdrawn'",
      name: "index_fleet_event_signups_unique_active_per_event"

    add_column :fleet_events, :signup_approval, :string, default: "direct", null: false
    add_column :fleet_event_slots, :signup_approval, :string
  end

  def down
    remove_column :fleet_event_slots, :signup_approval
    remove_column :fleet_events, :signup_approval

    if index_exists?(:fleet_event_signups, [:fleet_event_id, :fleet_membership_id], name: "index_fleet_event_signups_unique_active_per_event")
      remove_index :fleet_event_signups, name: "index_fleet_event_signups_unique_active_per_event"
    end

    add_index :fleet_event_signups, [:fleet_event_slot_id, :fleet_membership_id],
      unique: true,
      where: "status <> 'withdrawn'",
      name: "index_fleet_event_signups_unique_active"

    change_column_null :fleet_event_signups, :fleet_event_slot_id, false
    remove_reference :fleet_event_signups, :fleet_event, foreign_key: true
  end
end
