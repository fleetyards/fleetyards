# frozen_string_literal: true

class AddFleetSquadronToTeams < ActiveRecord::Migration[8.1]
  def change
    add_reference :fleet_event_teams, :fleet_squadron,
      type: :uuid,
      foreign_key: {on_delete: :nullify},
      index: true

    add_reference :mission_teams, :fleet_squadron,
      type: :uuid,
      foreign_key: {on_delete: :nullify},
      index: true
  end
end
