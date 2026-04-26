# frozen_string_literal: true

module Maintenance
  class AddInventoryPrivilegesTask < MaintenanceTasks::Task
    def collection
      FleetRole.all
    end

    def count
      collection.count
    end

    def process(role)
      access = role.resource_access
      access = YAML.safe_load(access, permitted_classes: [Symbol]) if access.is_a?(String)
      return unless access.is_a?(Array)

      # Skip if already has inventory privileges
      return if access.any? { |a| a.to_s.start_with?("fleet:inventories:") }

      # Skip admin roles — fleet:manage already implies all privileges
      return if access.any? { |a| a.to_s == "fleet:manage" }

      new_access = if access.any? { |a| a.to_s == "fleet:roles:manage" || a.to_s == "fleet:memberships:manage" }
        access + ["fleet:inventories:manage"]
      else
        access + ["fleet:inventories:read"]
      end

      role.update_column(:resource_access, new_access.to_yaml)
    end
  end
end
