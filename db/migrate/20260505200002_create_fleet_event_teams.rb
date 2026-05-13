# frozen_string_literal: true

class CreateFleetEventTeams < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_event_teams, id: :uuid do |t|
      t.references :fleet_event, type: :uuid, null: false, foreign_key: true
      t.uuid :source_team_id
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :fleet_event_teams, [:fleet_event_id, :position]
    add_foreign_key :fleet_event_teams, :mission_teams, column: :source_team_id, on_delete: :nullify
  end
end
