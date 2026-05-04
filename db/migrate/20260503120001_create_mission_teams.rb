# frozen_string_literal: true

class CreateMissionTeams < ActiveRecord::Migration[7.2]
  def change
    create_table :mission_teams, id: :uuid do |t|
      t.references :mission, type: :uuid, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :mission_teams, [:mission_id, :position]
  end
end
