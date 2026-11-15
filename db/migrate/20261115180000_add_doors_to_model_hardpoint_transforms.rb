# frozen_string_literal: true

class AddDoorsToModelHardpointTransforms < ActiveRecord::Migration[8.1]
  def change
    add_column :model_hardpoint_transforms, :doors, :jsonb
    change_column_null :model_hardpoint_transforms, :data, true
  end
end
