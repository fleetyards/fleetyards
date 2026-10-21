# frozen_string_literal: true

# What taking a mission costs and how it comes round again: the aUEC buy-in, the
# minutes the contract states it takes, how many a player may hold at once, and
# the minutes before it is offered again.
class AddTermsToGameMissions < ActiveRecord::Migration[8.1]
  def change
    %i[game_missions game_mission_builds].each do |table|
      add_column table, :buy_in, :integer
      add_column table, :time_to_complete, :decimal, precision: 8, scale: 2
      add_column table, :max_instances_per_player, :integer
      add_column table, :respawn_time, :decimal, precision: 8, scale: 2
      add_column table, :respawn_variation, :decimal, precision: 8, scale: 2
    end
  end
end
