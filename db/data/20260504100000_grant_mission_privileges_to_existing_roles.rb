# frozen_string_literal: true

class GrantMissionPrivilegesToExistingRoles < ActiveRecord::Migration[8.1]
  def up
    FleetRole.find_each do |role|
      access = Array(role.resource_access)
      added = []

      # All members get read
      added << "fleet:missions:read" unless access.include?("fleet:missions:read")

      # Officer-equivalents (anyone with manage on something else) get manage
      if access.include?("fleet:manage") || access.include?("fleet:memberships:manage")
        added << "fleet:missions:manage" unless access.include?("fleet:missions:manage")
      end

      next if added.empty?

      role.update_columns(resource_access: (access + added).uniq)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
