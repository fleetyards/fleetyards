# frozen_string_literal: true

class CreateFleetEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_events, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false, foreign_key: true, index: false
      t.uuid :mission_id, null: true
      t.uuid :created_by_id, null: false

      t.string :title, null: false
      t.text :description
      t.text :briefing
      t.string :slug, null: false

      t.string :status, null: false, default: "draft"

      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :timezone, null: false, default: "UTC"

      t.string :location
      t.string :meetup_location

      t.string :visibility, null: false, default: "members"

      t.integer :category, null: false, default: 0
      t.string :scenario
      t.string :cover_image_preset

      t.integer :max_attendees
      t.boolean :auto_lock_enabled, null: false, default: true
      t.integer :auto_lock_minutes_before, null: false, default: 60
      t.text :cancelled_reason
      t.datetime :starting_soon_notified_at

      t.uuid :external_uid, null: false

      t.string :discord_event_id
      t.string :discord_message_id
      t.datetime :discord_synced_at

      t.datetime :archived_at

      t.timestamps
    end

    add_index :fleet_events, [:fleet_id, :slug], unique: true
    add_index :fleet_events, [:fleet_id, :status]
    add_index :fleet_events, [:fleet_id, :starts_at]
    add_index :fleet_events, :mission_id
    add_index :fleet_events, :external_uid, unique: true
    add_foreign_key :fleet_events, :missions, column: :mission_id
    add_foreign_key :fleet_events, :users, column: :created_by_id
  end
end
