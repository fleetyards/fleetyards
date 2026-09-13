# frozen_string_literal: true

# `Fleet#setup_default_roles!` only runs when a fleet is created, so the preset
# privileges a new group ships with never reach a role that already exists.
# Without this every fleet on the site gets a 403 on a feature that looks
# switched on.
class GrantContractPrivilegesToExistingRoles < ActiveRecord::Migration[8.1]
  def up
    FleetRole.find_each do |role|
      access = Array(role.resource_access)
      added = []

      # Everyone can see the job board, and take a job off it.
      added << "fleet:contracts:read" unless access.include?("fleet:contracts:read")

      # Officer-equivalents -- anyone already trusted to manage something -- can
      # post and settle them.
      if access.include?("fleet:manage") || access.include?("fleet:memberships:manage")
        added << "fleet:contracts:manage" unless access.include?("fleet:contracts:manage")
      end

      next if added.empty?

      role.update_columns(resource_access: (access + added).uniq)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
