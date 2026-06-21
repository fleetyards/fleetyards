# frozen_string_literal: true

class AddRecurrenceToFleetEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_events, :recurring, :boolean, null: false, default: false
    add_column :fleet_events, :recurrence_interval, :string
    add_column :fleet_events, :recurrence_until, :date
    add_column :fleet_events, :recurrence_count, :integer
    add_column :fleet_events, :excluded_dates, :date, array: true, null: false, default: []

    add_index :fleet_events, [:fleet_id, :recurring]
  end
end
