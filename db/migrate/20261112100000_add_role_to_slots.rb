# frozen_string_literal: true

class AddRoleToSlots < ActiveRecord::Migration[8.1]
  def up
    add_column :mission_slots, :role, :string
    add_column :fleet_event_slots, :role, :string

    %w[mission_slots fleet_event_slots].each do |table|
      execute <<~SQL.squish
        UPDATE #{table} SET role = 'pilot'
        FROM model_positions
        WHERE model_positions.id = #{table}.model_position_id
          AND model_positions.position_type = 0
      SQL
    end

    execute <<~SQL.squish
      INSERT INTO mission_slots (id, slottable_type, slottable_id, title, position, role, created_at, updated_at)
      SELECT gen_random_uuid(), 'MissionShip', mission_ships.id, 'Pilot', -1, 'pilot', NOW(), NOW()
      FROM mission_ships
      INNER JOIN mission_teams ON mission_teams.id = mission_ships.mission_team_id
      WHERE mission_teams.fleet_squadron_flight_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM mission_slots
          WHERE mission_slots.slottable_type = 'MissionShip'
            AND mission_slots.slottable_id = mission_ships.id
            AND mission_slots.role = 'pilot'
        )
    SQL
  end

  def down
    remove_column :fleet_event_slots, :role
    remove_column :mission_slots, :role
  end
end
