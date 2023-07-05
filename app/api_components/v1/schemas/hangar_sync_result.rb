# frozen_string_literal: true

module V1
  module Schemas
    class HangarSyncResult
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          importedVehicles: {type: :array, items: {type: :string, format: :uuid}},
          foundVehicles: {type: :array, items: {type: :string, format: :uuid}},
          movedVehiclesToWanted: {type: :array, items: {type: :string, format: :uuid}},
          missingModels: {type: :array, items: {type: :string}},
          importedComponents: {type: :array, items: {type: :string, format: :uuid}},
          foundComponents: {type: :array, items: {type: :string, format: :uuid}},
          missingComponents: {type: :array, items: {type: :string}},
          missingComponentVehicles: {type: :array, items: {type: :string}},
          importedUpgrades: {type: :array, items: {type: :string, format: :uuid}},
          foundUpgrades: {type: :array, items: {type: :string, format: :uuid}},
          missingUpgrades: {type: :array, items: {type: :string}},
          missingUpgradeVehicles: {type: :array, items: {type: :string}}
        },
        required: %w[
          importedVehicles foundVehicles movedVehiclesToWanted missingModels importedComponents
          foundComponents missingComponents missingComponentVehicles importedUpgrades foundUpgrades
          missingUpgrades missingUpgradeVehicles
        ]
      })
    end
  end
end
