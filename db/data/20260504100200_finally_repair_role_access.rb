# frozen_string_literal: true

class FinallyRepairRoleAccess < ActiveRecord::Migration[8.1]
  def up
    FleetRole.find_each do |role|
      raw = role.read_attribute_before_type_cast(:resource_access)
      next if raw.blank?

      decoded = YAML.safe_load(raw, permitted_classes: [Symbol], aliases: true)

      # Unwrap any level of double encoding until we have an Array
      while decoded.is_a?(String)
        decoded = YAML.safe_load(decoded, permitted_classes: [Symbol], aliases: true)
      end

      next unless decoded.is_a?(Array)

      role.update_columns(resource_access: decoded)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
