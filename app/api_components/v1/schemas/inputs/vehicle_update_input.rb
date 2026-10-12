# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: [:string, :null]},
            serial: {type: [:string, :null]},
            wanted: {type: :boolean},
            nameVisible: {type: :boolean},
            public: {type: :boolean},
            saleNotify: {type: :boolean},
            logEntriesPublicByDefault: {type: :boolean},
            location: {type: [:string, :null]},
            locationId: {type: [:string, :null], format: :uuid},
            dedication: {type: [:string, :null], maxLength: ::Vehicle::DEDICATION_LIMIT},
            launchedOn: {type: [:string, :null], format: :date},
            launchPort: {type: [:string, :null], maxLength: ::Vehicle::PLAQUE_LINE_LIMIT},
            launchPortLocationId: {type: [:string, :null], format: :uuid},
            affiliation: {type: [:string, :null], maxLength: ::Vehicle::PLAQUE_LINE_LIMIT},
            operationsGroup: ::V1::Schemas::Enums::NullableVehicleOperationsGroupEnum,
            image: {type: [:string, :null]},
            modelImageId: {type: [:string, :null], format: :uuid},
            flagship: {type: :boolean},
            modelPaintId: {type: [:string, :null], format: :uuid},
            boughtVia: ::Shared::V1::Schemas::Enums::BoughtViaEnum,
            hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}},
            modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
            modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}},
            alternativeNames: {type: :array, items: {type: :string}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
