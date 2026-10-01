require "test_helper"

# The parser writes a draw and a signature onto any item that has them, so a
# closed component schema that omits them describes a payload the API can
# serve and a client cannot type. `typeData` is an anyOf, so a response test
# does not catch it: the payload matches a looser sibling instead.
class ComponentPowerSchemaTest < ActiveSupport::TestCase
  POWER_FIELDS = %w[powerConsumption powerMinimumFraction powerRanges signatureEm signatureIr].freeze

  POWERED_SCHEMAS = %w[
    ComponentThruster ComponentRadar ComponentShield ComponentLifeSupport ComponentEmp
    ComponentQuantumEnforcement ComponentJumpDrive ComponentQuantumDrive ComponentWeapon
  ].freeze

  test "every powered component schema carries the power and signature fields" do
    schemas = YAML.load_file(Rails.root.join("swagger/v1/schema.yaml")).dig("components", "schemas")

    missing = POWERED_SCHEMAS.to_h { |name|
      [name, POWER_FIELDS - schemas.dig(name, "properties").to_h.keys]
    }.reject { |_name, fields| fields.empty? }

    assert_empty missing
  end
end
