# frozen_string_literal: true

class CreateFleetEventOccurrenceStates < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_event_occurrence_states, id: :uuid do |t|
      t.references :fleet_event, type: :uuid, null: false, foreign_key: true,
        index: false
      t.date :occurrence_date, null: false

      # Lifecycle state for this occurrence. nil means "inherit from event".
      t.string :status
      t.datetime :locked_at
      t.datetime :starting_soon_notified_at
      t.datetime :cancelled_at
      t.text :cancelled_reason

      # Discord per-occurrence tracking.
      t.string :discord_event_id
      t.datetime :discord_synced_at

      # Per-occurrence override fields. nil means "inherit from event".
      t.string :title
      t.text :description
      t.text :briefing
      t.string :location
      t.string :meetup_location
      t.string :scenario
      t.string :cover_image_preset

      t.timestamps
    end

    add_index :fleet_event_occurrence_states,
      [:fleet_event_id, :occurrence_date],
      unique: true,
      name: "idx_fleet_event_occurrence_states_on_event_and_date"
  end
end
