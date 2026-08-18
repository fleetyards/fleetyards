# frozen_string_literal: true

class CreateMissionSlots < ActiveRecord::Migration[7.2]
  def change
    create_table :mission_slots, id: :uuid do |t|
      t.string :slottable_type, null: false
      t.uuid :slottable_id, null: false
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :mission_slots, [:slottable_type, :slottable_id]
    add_index :mission_slots, [:slottable_type, :slottable_id, :position],
      name: "index_mission_slots_on_slottable_and_position"
  end
end
