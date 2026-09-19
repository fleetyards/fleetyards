# frozen_string_literal: true

# `Fleet#setup_default_roles!` only runs when a fleet is created, so the preset
# privileges a new group ships with never reach a role that already exists.
# Without this every fleet on the site gets a 403 on a tab that looks switched
# on.
class GrantBlueprintPrivilegesToExistingRoles < ActiveRecord::Migration[8.1]
  # What a blueprint list actually discloses is *who* holds each recipe --
  # usernames, the fleet's nickname for them, their avatar. A role that can
  # already see the roster or the ship list has been trusted with exactly that;
  # a custom role deliberately cut off from both has not, and a backfill is no
  # place to overturn that decision. Those roles get nothing, and a fleet that
  # wants them to read recipes grants it on the roles page.
  ALREADY_SEES_MEMBERS = %w[
    fleet:memberships:manage
    fleet:memberships:read
    fleet:vehicles:manage
    fleet:vehicles:read
  ].freeze

  def up
    FleetRole.find_each do |role|
      access = Array(role.resource_access)

      next if access.include?("fleet:blueprints:read")

      # A role that manages the whole fleet already passes the check, and the
      # roles page renders the privilege as implied rather than as held.
      # Writing it anyway would turn that into a plain tick and quietly say
      # something different about the role.
      next if access.include?("fleet:manage")

      next if access.intersection(ALREADY_SEES_MEMBERS).empty?

      role.update_columns(resource_access: access + ["fleet:blueprints:read"])
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
