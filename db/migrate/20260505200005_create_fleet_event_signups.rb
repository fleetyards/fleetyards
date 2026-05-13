# frozen_string_literal: true

class CreateFleetEventSignups < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_event_signups, id: :uuid do |t|
      t.references :fleet_event_slot, type: :uuid, null: false, foreign_key: true
      t.references :fleet_membership, type: :uuid, null: false, foreign_key: true
      t.uuid :vehicle_id
      t.string :status, null: false, default: "confirmed"
      t.text :notes
      t.datetime :confirmed_at
      t.datetime :withdrawn_at
      t.timestamps
    end

    add_index :fleet_event_signups, [:fleet_event_slot_id, :fleet_membership_id],
      unique: true,
      where: "status != 'withdrawn'",
      name: "index_fleet_event_signups_unique_active"
    add_foreign_key :fleet_event_signups, :vehicles, column: :vehicle_id, on_delete: :nullify
  end
end
