# frozen_string_literal: true

class CreateFleetEventSlots < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_event_slots, id: :uuid do |t|
      t.string :slottable_type, null: false
      t.uuid :slottable_id, null: false
      t.uuid :source_slot_id
      t.references :model_position, type: :uuid, null: true, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :fleet_event_slots, [:slottable_type, :slottable_id]
    add_index :fleet_event_slots, [:slottable_type, :slottable_id, :position],
      name: "index_fleet_event_slots_on_slottable_and_position"
    add_foreign_key :fleet_event_slots, :mission_slots, column: :source_slot_id, on_delete: :nullify
  end
end
