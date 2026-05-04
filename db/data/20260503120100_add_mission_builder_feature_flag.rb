# frozen_string_literal: true

class AddMissionBuilderFeatureFlag < ActiveRecord::Migration[8.1]
  def up
    Flipper.add("mission_builder")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
