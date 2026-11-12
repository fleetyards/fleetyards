# frozen_string_literal: true

class AddTeamSeatToFleetEventSignups < ActiveRecord::Migration[8.1]
  def up
    add_column :fleet_event_signups, :team_seat, :boolean, null: false, default: false

    execute <<~SQL.squish
      UPDATE fleet_event_signups
      SET team_seat = TRUE
      FROM fleet_event_slots
      WHERE fleet_event_slots.id = fleet_event_signups.fleet_event_slot_id
        AND fleet_event_slots.slottable_type = 'FleetEventTeam'
    SQL

    remove_index :fleet_event_signups, name: "index_fleet_event_signups_unique_active_per_event"
    add_index :fleet_event_signups,
      [:fleet_event_id, :occurrence_date, :fleet_membership_id],
      unique: true,
      where: "((status)::text <> 'withdrawn'::text) AND NOT team_seat",
      nulls_not_distinct: true,
      name: "index_fleet_event_signups_unique_active_per_event"
    add_index :fleet_event_signups,
      [:fleet_event_id, :occurrence_date, :fleet_membership_id],
      unique: true,
      where: "((status)::text <> 'withdrawn'::text) AND team_seat",
      nulls_not_distinct: true,
      name: "index_fleet_event_signups_unique_active_team_seat_per_event"
  end

  def down
    remove_index :fleet_event_signups, name: "index_fleet_event_signups_unique_active_team_seat_per_event"
    remove_index :fleet_event_signups, name: "index_fleet_event_signups_unique_active_per_event"
    add_index :fleet_event_signups,
      [:fleet_event_id, :occurrence_date, :fleet_membership_id],
      unique: true,
      where: "((status)::text <> 'withdrawn'::text)",
      nulls_not_distinct: true,
      name: "index_fleet_event_signups_unique_active_per_event"
    remove_column :fleet_event_signups, :team_seat
  end
end
