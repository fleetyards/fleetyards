# frozen_string_literal: true

class RestructureMissionShipsUnderTeams < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :mission_ships, :missions
    remove_index :mission_ships, [:mission_id, :position] if index_exists?(:mission_ships, [:mission_id, :position])
    remove_index :mission_ships, :mission_id if index_exists?(:mission_ships, :mission_id)
    remove_column :mission_ships, :mission_id, :uuid

    add_reference :mission_ships, :mission_team, type: :uuid, null: false, foreign_key: true
    add_index :mission_ships, [:mission_team_id, :position]

    add_reference :mission_slots, :model_position, type: :uuid, null: true, foreign_key: true
  end
end
