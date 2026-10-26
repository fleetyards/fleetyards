# frozen_string_literal: true

class CreateModelHardpointTransforms < ActiveRecord::Migration[8.1]
  def change
    # Beside the model rather than on it: a port list runs to tens of kilobytes
    # and only the loadout preview reads it, where every list selects models.*.
    create_table :model_hardpoint_transforms, id: :uuid do |t|
      t.references :model, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: {unique: true}
      t.jsonb :data, null: false
      t.timestamps
    end
  end
end
