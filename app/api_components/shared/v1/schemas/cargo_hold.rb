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
            offset: CargoHoldOffset,
            rotation: {type: :integer}
          },
          additionalProperties: false,
          required: %w[dimensions capacity maxContainerSize limits]
        })
      end
    end
  end
end
