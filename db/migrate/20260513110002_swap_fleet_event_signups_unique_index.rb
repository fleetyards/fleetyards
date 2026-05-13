# frozen_string_literal: true

class SwapFleetEventSignupsUniqueIndex < ActiveRecord::Migration[8.1]
  def up
    remove_index :fleet_event_signups,
      name: "index_fleet_event_signups_unique_active_per_event"
    add_index :fleet_event_signups,
      [:fleet_event_id, :occurrence_date, :fleet_membership_id],
      unique: true,
      where: "((status)::text <> 'withdrawn'::text)",
      name: "index_fleet_event_signups_unique_active_per_event"
  end

  def down
    remove_index :fleet_event_signups,
      name: "index_fleet_event_signups_unique_active_per_event"
    add_index :fleet_event_signups,
      [:fleet_event_id, :fleet_membership_id],
      unique: true,
      where: "((status)::text <> 'withdrawn'::text)",
      name: "index_fleet_event_signups_unique_active_per_event"
  end
end
