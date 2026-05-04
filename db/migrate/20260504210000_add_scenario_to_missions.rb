# frozen_string_literal: true

class AddScenarioToMissions < ActiveRecord::Migration[7.2]
  def change
    add_column :missions, :scenario, :string
    add_index :missions, [:fleet_id, :scenario]
  end
end
