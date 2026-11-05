# frozen_string_literal: true

class AddLadderAndOutcomeToGameMissionRewards < ActiveRecord::Migration[8.1]
  def change
    add_column :game_mission_rewards, :ladder_key, :string
    add_column :game_mission_rewards, :ladder_name, :string
    add_column :game_mission_rewards, :outcome, :string
  end
end
