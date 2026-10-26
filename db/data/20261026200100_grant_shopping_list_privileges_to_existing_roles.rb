# frozen_string_literal: true

# `Fleet#setup_default_roles!` only runs when a fleet is created, so the preset
# privileges a new group ships with never reach a role that already exists.
class GrantShoppingListPrivilegesToExistingRoles < ActiveRecord::Migration[8.1]
  def up
    FleetRole.find_each do |role|
      access = Array(role.resource_access)
      added = []

      added << "fleet:shopping_lists:read" unless access.include?("fleet:shopping_lists:read")

      # Whoever already looks after the fleet's stores keeps its kit lists too.
      if access.include?("fleet:manage") || access.include?("fleet:inventories:manage")
        added << "fleet:shopping_lists:manage" unless access.include?("fleet:shopping_lists:manage")
      end

      next if added.empty?

      role.update_columns(resource_access: (access + added).uniq)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
