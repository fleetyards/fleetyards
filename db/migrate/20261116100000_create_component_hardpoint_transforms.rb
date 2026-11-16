# frozen_string_literal: true

class CreateComponentHardpointTransforms < ActiveRecord::Migration[8.1]
  def change
    # A module's hull export, beside the component as a ship's is beside the
    # model: only the loadout preview reads it, and lists select components.*.
    create_table :component_hardpoint_transforms, id: :uuid do |t|
      t.references :component, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: {unique: true}
      t.jsonb :data
      t.jsonb :doors
      t.timestamps
    end
  end
end
