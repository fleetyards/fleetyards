# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class CargoHoldLimits
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            min: ::Shared::V1::Schemas::CargoHoldLimit,
            max: ::Shared::V1::Schemas::CargoHoldLimit
          },
          additionalProperties: false,
          required: %w[min]
        })
      end
    end
  end
end
