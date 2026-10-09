# frozen_string_literal: true

class GrantAnnouncementPrivilegesToExistingRoles < ActiveRecord::Migration[8.1]
  # FleetRole.setup_default_roles! only runs when a fleet is created, so a new
  # privilege group reaches nobody who already exists. Officers are recognised
  # the way the payout rollout recognised them: by running the membership.
  def up
    FleetRole.find_each do |role|
      access = Array(role.resource_access)
      next unless access.include?("fleet:memberships:manage")
      next if access.include?("fleet:announcements:manage")

      role.update_columns(resource_access: access + ["fleet:announcements:manage"])
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
