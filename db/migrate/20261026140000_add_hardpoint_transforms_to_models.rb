# frozen_string_literal: true

class AddHardpointTransformsToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :hardpoint_transforms, :jsonb
  end
end
