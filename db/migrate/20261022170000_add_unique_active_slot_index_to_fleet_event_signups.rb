# frozen_string_literal: true

class AddUniqueActiveSlotIndexToFleetEventSignups < ActiveRecord::Migration[8.1]
  def change
    add_index :fleet_event_signups, %i[fleet_event_slot_id occurrence_date],
      name: "index_fleet_event_signups_unique_active_per_slot",
      unique: true,
      nulls_not_distinct: true,
      where: "fleet_event_slot_id IS NOT NULL AND status <> 'withdrawn'"
  end
end
