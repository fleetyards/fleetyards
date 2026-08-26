# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ModelMetrics
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            beam: {type: :number},
            beamLabel: {type: :string},
            cargo: {type: :number},
            cargoLabel: {type: :string},
            personalInventory: {type: :number},
            personalInventoryLabel: {type: [:string, :null]},
            fleetchartOffsetLength: {type: :number},
            fleetchartOffsetBeam: {type: :number},
            extendedLength: {type: :number},
            extendedLengthLabel: {type: :string},
            extendedBeam: {type: :number},
            extendedBeamLabel: {type: :string},
            extendedHeight: {type: :number},
            extendedHeightLabel: {type: :string},
            extendedFleetchartOffsetLength: {type: :number},
            extendedFleetchartOffsetBeam: {type: :number},
            height: {type: :number},
            heightLabel: {type: :string},
            hydrogenFuelTankSize: {type: :number},
            isGroundVehicle: {type: :boolean},
            length: {type: :number},
            lengthLabel: {type: :string},
            mass: {type: :number},
            massLabel: {type: :string},
            hullHealth: {type: :number},
            hullParts: {
              type: :array,
              items: Shared::V1::Schemas::ModelHullPart
            },
            hullDoors: {
              type: :array,
              items: Shared::V1::Schemas::ModelHullDoor
            },
            quantumFuelTankSize: {type: :number},
            weaponPoolSize: {type: :number},
            signatureCrossSection: Shared::V1::Schemas::ModelSignatureCrossSection,
            size: {type: :string},
            sizeLabel: {type: :string},
            dockSize: {type: :string}
          },
          additionalProperties: false

        })
      end
    end
  end
end
