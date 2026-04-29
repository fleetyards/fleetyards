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
      raw = role.read_attribute_before_type_cast(:resource_access)
      return if raw.blank?

      # Peel YAML layers until we reach an Array
      value = YAML.safe_load(raw, permitted_classes: [Array])
      return if value.is_a?(Array)

      while value.is_a?(String)
        value = YAML.safe_load(value, permitted_classes: [Array])
      end

      return unless value.is_a?(Array)

      # update_column applies the serialize coder, so pass the array directly
      role.update_column(:resource_access, value)
    end
  end
end
