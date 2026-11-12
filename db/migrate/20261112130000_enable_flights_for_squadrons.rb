# frozen_string_literal: true

class EnableFlightsForSquadrons < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE fleet_squadrons SET flights_enabled = TRUE WHERE team = FALSE AND flights_enabled = FALSE"
  end

  def down
  end
end
