# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleLoadoutItemCraftedInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            blueprintId: {type: :string, format: :uuid, description: "A recipe that makes the fitted component"},
            qualities: {
              type: :array,
              items: ::V1::Schemas::Vehicles::CraftedSlotQuality,
              description: "A recipe slot left out was filled at the neutral grade, 500"
            }
          },
          additionalProperties: false,
          required: %w[blueprintId qualities]
        })
      end
    end
  end
end
