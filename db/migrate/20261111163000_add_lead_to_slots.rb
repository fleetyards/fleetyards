# frozen_string_literal: true

class AddLeadToSlots < ActiveRecord::Migration[8.1]
  def up
    add_column :mission_slots, :lead, :boolean, null: false, default: false
    add_column :fleet_event_slots, :lead, :boolean, null: false, default: false

    add_index :mission_slots, %i[slottable_type slottable_id], unique: true, where: "lead",
      name: "index_mission_slots_one_lead_per_slottable"
    add_index :fleet_event_slots, %i[slottable_type slottable_id], unique: true, where: "lead",
      name: "index_fleet_event_slots_one_lead_per_slottable"

    execute <<~SQL.squish
      INSERT INTO mission_slots (id, slottable_type, slottable_id, title, position, lead, created_at, updated_at)
      SELECT gen_random_uuid(), 'MissionTeam', mission_teams.id, 'Flight lead', -1, TRUE, NOW(), NOW()
      FROM mission_teams
      WHERE mission_teams.fleet_squadron_flight_id IS NOT NULL
    SQL
  end

  def down
    execute "DELETE FROM mission_slots WHERE lead"
    remove_index :fleet_event_slots, name: "index_fleet_event_slots_one_lead_per_slottable"
    remove_index :mission_slots, name: "index_mission_slots_one_lead_per_slottable"
    remove_column :fleet_event_slots, :lead
    remove_column :mission_slots, :lead
  end
end
