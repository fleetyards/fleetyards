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
            hiddenByUser: {type: :boolean},
            nameVisible: {type: :boolean},
            public: {type: :boolean},
            saleNotify: {type: :boolean},
            logEntriesPublicByDefault: {type: :boolean},
            location: {type: [:string, :null]},
            locationId: {type: [:string, :null], format: :uuid},
            dedication: {type: [:string, :null], maxLength: ::Vehicle::DEDICATION_LIMIT},
            dedicationVerse: {type: [:string, :null], maxLength: ::Vehicle::DEDICATION_VERSE_LIMIT},
            launchedOn: {type: [:string, :null], format: :date},
            launchPort: {type: [:string, :null], maxLength: ::Vehicle::PLAQUE_LINE_LIMIT},
            launchPortLocationId: {type: [:string, :null], format: :uuid},
            affiliation: {type: [:string, :null], maxLength: ::Vehicle::PLAQUE_LINE_LIMIT},
            operationsGroup: ::V1::Schemas::Enums::NullableVehicleOperationsGroupEnum,
            plaqueCaptain: {type: [:string, :null], maxLength: ::User::DISPLAY_NAME_LIMIT},
            plaqueStyle: ::V1::Schemas::Enums::NullableVehiclePlaqueStyleEnum,
            plaqueLocale: ::V1::Schemas::Enums::NullableVehiclePlaqueLocaleEnum,
            # A signed blob id of the plaque rendered as a picture.
            plaqueImage: {type: [:string, :null]},
            image: {type: [:string, :null]},
            # The picked picture: one of the model's gallery images, or one of
            # its paints, whose store image it shows.
            pictureType: ::V1::Schemas::Enums::NullableVehiclePictureTypeEnum,
            pictureId: {type: [:string, :null], format: :uuid},
            flagship: {type: :boolean},
            boughtVia: ::Shared::V1::Schemas::Enums::BoughtViaEnum,
            hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}},
            modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
            modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}},
            modelPaintIds: {type: :array, items: {type: :string, format: :uuid}},
            alternativeNames: {type: :array, items: {type: :string}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
