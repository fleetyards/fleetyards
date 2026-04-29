# frozen_string_literal: true

module Maintenance
  class FixDoubleSerializedResourceAccessTask < MaintenanceTasks::Task
    def collection
      FleetRole.all
    end

    def count
      collection.count
    end

    def process(role)
      access = role.resource_access
      return unless access.is_a?(String)

      parsed = YAML.safe_load(access, permitted_classes: [Array])
      return unless parsed.is_a?(Array)

      role.update_column(:resource_access, parsed.to_yaml)
    end
  end
end
