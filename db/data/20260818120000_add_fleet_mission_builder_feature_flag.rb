# frozen_string_literal: true

class AddFleetMissionBuilderFeatureFlag < ActiveRecord::Migration[8.1]
  def up
    Flipper.add("fleet_mission_builder")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
