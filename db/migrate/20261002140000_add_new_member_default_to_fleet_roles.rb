# frozen_string_literal: true

class AddNewMemberDefaultToFleetRoles < ActiveRecord::Migration[8.1]
  def up
    add_column :fleet_roles, :new_member_default, :boolean, null: false, default: false
    add_index :fleet_roles, :fleet_id, unique: true, where: "new_member_default",
      name: "index_fleet_roles_on_one_default_per_fleet"

    # What new members already got: the lowest-ranked role, unless that is the
    # permanent Admin role, which a new member must never get.
    execute <<~SQL.squish
      UPDATE fleet_roles SET new_member_default = TRUE
      WHERE id IN (
        SELECT DISTINCT ON (fleet_id) id FROM fleet_roles
        WHERE rank IS NOT NULL AND permanent IS NOT TRUE
        ORDER BY fleet_id, rank DESC
      )
    SQL
  end

  def down
    remove_index :fleet_roles, name: "index_fleet_roles_on_one_default_per_fleet"
    remove_column :fleet_roles, :new_member_default
  end
end
