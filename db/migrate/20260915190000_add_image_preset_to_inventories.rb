# frozen_string_literal: true

class AddImagePresetToInventories < ActiveRecord::Migration[8.1]
  def change
    # The picture somebody picked for a hold, the way fleet_contracts and
    # fleet_events already hold one. Nullable: an inventory with none keeps
    # taking the picture its name hashes to, which is what it showed before.
    add_column :inventories, :image_preset, :string
    add_column :fleet_inventories, :image_preset, :string
  end
end
