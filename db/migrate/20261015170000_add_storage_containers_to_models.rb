# frozen_string_literal: true

# Ore pods and salvage storage: what a mining or salvage ship holds that is not
# cargo space. A shape like `external_fuel_tanks`, filled from the game files on
# the next load.
class AddStorageContainersToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :storage_containers, :string
    add_column :model_builds, :storage_containers, :string
  end
end
