# frozen_string_literal: true

class AddOccurrenceDateToFleetEventSignups < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_event_signups, :occurrence_date, :date

    add_index :fleet_event_signups,
      [:fleet_event_id, :occurrence_date, :fleet_membership_id],
      name: "idx_fleet_event_signups_on_event_and_occurrence_and_member"
  end
end
