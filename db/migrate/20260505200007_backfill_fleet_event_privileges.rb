# frozen_string_literal: true

class BackfillFleetEventPrivileges < ActiveRecord::Migration[8.1]
  # Default fleet roles are seeded with these names (see FleetRole.setup_default_roles!).
  # Custom roles get nothing here — admins must grant the new event privileges manually.
  DEFAULT_ROLE_PRIVILEGES = {
    "Admin" => FleetEvent::DEFAULT_PRIVILEGES[:admin],
    "Officer" => FleetEvent::DEFAULT_PRIVILEGES[:officer],
    "Member" => FleetEvent::DEFAULT_PRIVILEGES[:member]
  }.freeze

  def up
    FleetRole.find_each do |role|
      defaults = DEFAULT_ROLE_PRIVILEGES[role.name]
      next if defaults.blank?

      current = Array(role.resource_access)
      missing = defaults - current
      next if missing.empty?

      role.update_columns(resource_access: (current + missing).uniq)
    end
  end

  def down
    # No-op: removing privileges could break custom-tweaked roles
  end
end
