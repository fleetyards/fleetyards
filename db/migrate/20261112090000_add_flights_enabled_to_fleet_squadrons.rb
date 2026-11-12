# frozen_string_literal: true

class AddFlightsEnabledToFleetSquadrons < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_squadrons, :flights_enabled, :boolean, null: false, default: false
  end
end
