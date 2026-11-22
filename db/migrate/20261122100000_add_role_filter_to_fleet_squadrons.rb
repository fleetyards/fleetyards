# frozen_string_literal: true

class AddRoleFilterToFleetSquadrons < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_squadrons, :classifications, :string, array: true, default: [], null: false
    add_column :fleet_squadrons, :foci, :string, array: true, default: [], null: false
  end
end
