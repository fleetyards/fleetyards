# frozen_string_literal: true

class AddTeamToFleetSquadrons < ActiveRecord::Migration[8.0]
  # A squadron is somewhere a member belongs, so belonging to two of them is
  # the exception rather than the rule -- the flag marks the exception, and
  # every squadron that existed before this was one of the ordinary kind.
  def change
    add_column :fleet_squadrons, :team, :boolean, default: false, null: false
  end
end
