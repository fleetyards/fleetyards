# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class CargoHold
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # The game files leave a hold unnamed often enough that
            # DerivedCargoHolds keys such holds by position to tell them apart.
            name: {type: [:string, :null]},
            dimensions: ::Shared::V1::Schemas::CargoHoldDimension,
            capacity: {type: :integer},
            maxContainerSize: ::Shared::V1::Schemas::CargoHoldContainerSize,
            limits: CargoHoldLimits,
            # Where the hull export placed the hold, in the values the loadout
            # preview serves its cargo grids with.
            position: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3, description: "The grid's centre"},
            rotation: {type: :array, items: {type: :number}, minItems: 4, maxItems: 4, description: "Quaternion x, y, z, w"},
            size: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3, description: "Metres along the grid's own x, up and depth axes"},
            placedIn: {type: :string, description: "The ship or module whose hull export the position and rotation come from, as `model/<slug>` or `model_module/<slug>`. Holds placed in the same one share a frame; a hold without it is not placed"}
          },
          additionalProperties: false,
          required: %w[dimensions capacity maxContainerSize limits]
        })
      end
    end
  end
end
