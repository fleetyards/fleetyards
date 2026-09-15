# frozen_string_literal: true

class AddCoverImagePresetToFleetContracts < ActiveRecord::Migration[8.1]
  def change
    # The picture a contract was given, the way fleet_events.cover_image_preset
    # already holds one. Nullable: an existing contract keeps falling back to
    # the art its kind resolves to, which is what it was showing before.
    add_column :fleet_contracts, :cover_image_preset, :string
  end
end
