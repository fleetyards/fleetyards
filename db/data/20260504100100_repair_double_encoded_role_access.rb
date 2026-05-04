# frozen_string_literal: true

class RepairDoubleEncodedRoleAccess < ActiveRecord::Migration[8.1]
  def up
    FleetRole.find_each do |role|
      raw = role.read_attribute_before_type_cast(:resource_access)
      next if raw.blank?

      first = YAML.safe_load(raw, permitted_classes: [Symbol], aliases: true)

      if first.is_a?(String)
        # Double-encoded — load again to get the real array
        actual = YAML.safe_load(first, permitted_classes: [Symbol], aliases: true)
        role.update_columns(resource_access: actual)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
