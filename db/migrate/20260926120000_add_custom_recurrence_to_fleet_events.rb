# frozen_string_literal: true

class AddCustomRecurrenceToFleetEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_events, :recurrence_every, :integer, null: false, default: 1
    add_column :fleet_events, :recurrence_weekdays, :integer, array: true, null: false, default: []
  end
end
