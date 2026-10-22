# frozen_string_literal: true

# A one-off event's signups have no occurrence date, and NULLs never collide
# in a unique index by default, so this index held nothing there: a member
# could hold two active signups on the same one-off event.
class CoverOneOffEventsInActiveSignupPerEventIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :fleet_event_signups, %i[fleet_event_id occurrence_date fleet_membership_id],
      name: "index_fleet_event_signups_unique_active_per_event",
      unique: true,
      where: "status <> 'withdrawn'"
    add_index :fleet_event_signups, %i[fleet_event_id occurrence_date fleet_membership_id],
      name: "index_fleet_event_signups_unique_active_per_event",
      unique: true,
      nulls_not_distinct: true,
      where: "status <> 'withdrawn'"
  end
end
