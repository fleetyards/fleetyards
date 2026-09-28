# frozen_string_literal: true

class AddLocationKindToGameMissions < ActiveRecord::Migration[8.1]
  def change
    %i[game_missions game_mission_builds].each do |table|
      add_column table, :location_kind, :string
      add_column table, :needs_landing, :boolean, default: false, null: false
    end
  end
end
