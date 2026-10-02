# frozen_string_literal: true

class CreateFleetSquadronRoles < ActiveRecord::Migration[8.1]
  # Frozen here rather than read from FleetSquadronRole: the migration has to
  # seed what existed at its own moment, whatever the model says later.
  DEFAULTS = [
    ["leader", "Squadron Leader", 0],
    ["co_leader", "Co-Leader", 1],
    ["officer", "Squadron Officer", 2],
    ["member", "Member", 3]
  ].freeze

  def up
    create_table :fleet_squadron_roles, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false, foreign_key: true, index: false
      t.string :key, null: false
      t.string :name, null: false
      t.integer :position, null: false
      t.timestamps
    end

    add_index :fleet_squadron_roles, [:fleet_id, :key], unique: true

    add_reference :fleet_squadron_memberships, :fleet_squadron_role, type: :uuid, foreign_key: true

    values = DEFAULTS.map { |key, name, position| "(#{quote(key)}, #{quote(name)}, #{position})" }.join(", ")

    execute <<~SQL.squish
      INSERT INTO fleet_squadron_roles (fleet_id, key, name, position, created_at, updated_at)
      SELECT fleets.id, defaults.key, defaults.name, defaults.position, NOW(), NOW()
      FROM fleets CROSS JOIN (VALUES #{values}) AS defaults (key, name, position)
    SQL

    execute <<~SQL.squish
      UPDATE fleet_squadron_memberships
      SET fleet_squadron_role_id = fleet_squadron_roles.id
      FROM fleet_squadrons, fleet_squadron_roles
      WHERE fleet_squadrons.id = fleet_squadron_memberships.fleet_squadron_id
        AND fleet_squadron_roles.fleet_id = fleet_squadrons.fleet_id
        AND fleet_squadron_roles.key = 'member'
    SQL

    change_column_null :fleet_squadron_memberships, :fleet_squadron_role_id, false
  end

  def down
    remove_reference :fleet_squadron_memberships, :fleet_squadron_role, foreign_key: true
    drop_table :fleet_squadron_roles
  end

  private def quote(value)
    connection.quote(value)
  end
end
