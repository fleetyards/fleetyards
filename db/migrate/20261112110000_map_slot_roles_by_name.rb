# frozen_string_literal: true

class MapSlotRolesByName < ActiveRecord::Migration[8.1]
  NAMES = {
    "captain" => ["captain", "kapitän", "capitán", "capitaine", "capitano", "舰长", "艦長"],
    "pilot" => ["pilot", "piloto", "pilote", "pilota", "驾驶员", "駕駛員"]
  }.freeze

  def up
    %w[mission_slots fleet_event_slots].each do |table|
      NAMES.each do |role, names|
        quoted = names.map { |name| connection.quote(name) }.join(", ")

        execute <<~SQL.squish
          UPDATE #{table} SET role = #{connection.quote(role)}
          WHERE role IS NULL AND lead = FALSE AND LOWER(TRIM(title)) IN (#{quoted})
        SQL

        execute <<~SQL.squish
          UPDATE #{table} SET role = #{connection.quote(role)}
          FROM model_positions
          WHERE #{table}.role IS NULL
            AND model_positions.id = #{table}.model_position_id
            AND LOWER(TRIM(model_positions.name)) IN (#{quoted})
        SQL
      end
    end

    # The pilot seat added to flight ships that had none on record goes again
    # where the ship turns out to have one after all.
    execute <<~SQL.squish
      DELETE FROM mission_slots added
      WHERE added.role = 'pilot' AND added.position = -1 AND added.title = 'Pilot'
        AND added.slottable_type = 'MissionShip'
        AND NOT EXISTS (SELECT 1 FROM mission_slot_candidates WHERE mission_slot_candidates.mission_slot_id = added.id)
        AND EXISTS (
          SELECT 1 FROM mission_slots other
          WHERE other.slottable_type = 'MissionShip'
            AND other.slottable_id = added.slottable_id
            AND other.role = 'pilot'
            AND other.id <> added.id
        )
    SQL
  end

  def down
  end
end
