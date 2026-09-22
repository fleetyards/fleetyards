# frozen_string_literal: true

class AddPositionToFleetSquadrons < ActiveRecord::Migration[8.0]
  def up
    add_column :fleet_squadrons, :position, :integer, default: 0, null: false
    add_index :fleet_squadrons, %i[fleet_id position]

    # The order they were listed in until now, so nothing moves on the way in.
    execute <<~SQL.squish
      UPDATE fleet_squadrons
      SET position = ordered.row_number
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY fleet_id ORDER BY name ASC) AS row_number
        FROM fleet_squadrons
      ) AS ordered
      WHERE fleet_squadrons.id = ordered.id
    SQL
  end

  def down
    remove_index :fleet_squadrons, %i[fleet_id position]
    remove_column :fleet_squadrons, :position
  end
end
