# frozen_string_literal: true

# `Fleet#setup_default_roles!` only runs when a fleet is created, so the preset
# privileges a new group ships with never reach a role that already exists.
# Without this every fleet on the site gets a 403 on a tab that looks switched
# on.
class GrantSquadronPrivilegesToExistingRoles < ActiveRecord::Migration[8.1]
  def up
    FleetRole.find_each do |role|
      access = Array(role.resource_access)

      # A role that manages the whole fleet already passes every squadron
      # check, and the roles page renders those privileges as implied rather
      # than as held. Writing them anyway would turn that into a plain tick and
      # quietly say something different about the role.
      next if access.include?("fleet:manage")

      added = []

      # A squadron list is the roster grouped, so it discloses no more than the
      # roster does -- and reading it is what every member needs for the tab to
      # work at all.
      added << "fleet:squadrons:read" unless access.include?("fleet:squadrons:read")

      # Officer-equivalents -- anyone already trusted with the roster -- post
      # people to squadrons. Creating and deleting the squadrons themselves
      # stays with the admins, which is what the preset seeds.
      if access.include?("fleet:memberships:manage")
        added << "fleet:squadrons:members:manage" unless access.include?("fleet:squadrons:members:manage")
      end

      next if added.empty?

      role.update_columns(resource_access: (access + added).uniq)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
