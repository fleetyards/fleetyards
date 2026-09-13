# frozen_string_literal: true

class GrantPayoutPrivilegesToExistingRoles < ActiveRecord::Migration[8.1]
  # FleetRole.setup_default_roles! only runs when a fleet is created, so adding
  # a privilege group to PRIVILEGE_GROUPS grants it to nobody who already
  # exists. Without this every fleet on the site would get a 403 on a feature
  # that looks switched on. Mirrors the mission rollout.
  def up
    FleetRole.find_each do |role|
      access = Array(role.resource_access)
      added = []

      added << "fleet:payouts:read" unless access.include?("fleet:payouts:read")
      added << "fleet:payouts:create" unless access.include?("fleet:payouts:create")

      if access.include?("fleet:manage") || access.include?("fleet:memberships:manage")
        added << "fleet:payouts:manage" unless access.include?("fleet:payouts:manage")
      end

      next if added.empty?

      role.update_columns(resource_access: (access + added).uniq)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
