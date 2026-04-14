# frozen_string_literal: true

class AddFleetStarmapFeatureFlag < ActiveRecord::Migration[8.1]
  def up
    Flipper.add("fleet_starmap")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
