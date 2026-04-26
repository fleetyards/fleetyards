# frozen_string_literal: true

class AddFleetLogisticsFeatureFlag < ActiveRecord::Migration[8.1]
  def up
    Flipper.add("fleet_logistics")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
