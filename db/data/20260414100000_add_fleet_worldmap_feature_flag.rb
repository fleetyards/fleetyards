# frozen_string_literal: true

class AddFleetWorldmapFeatureFlag < ActiveRecord::Migration[8.1]
  def up
    Flipper.add("fleet_worldmap")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
