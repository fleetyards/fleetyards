# frozen_string_literal: true

# `Fleet#setup_default_roles!` only runs when a fleet is created, so the preset
# privileges a new group ships with never reach a role that already exists.
# Without this every fleet on the site gets a 403 on a tab that looks switched
# on.
class GrantBlueprintPrivilegesToExistingRoles < ActiveRecord::Migration[8.1]
  def up
    FleetRole.find_each do |role|
      access = Array(role.resource_access)

      next if access.include?("fleet:blueprints:read")

      # A role that manages the whole fleet already passes the check, and the
      # roles page renders the privilege as implied rather than as held.
      # Writing it anyway would turn that into a plain tick and quietly say
      # something different about the role.
      next if access.include?("fleet:manage")

      role.update_columns(resource_access: access + ["fleet:blueprints:read"])
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
