# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadoutItemCrafted
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            blueprintId: {type: :string, format: :uuid},
            blueprintSlug: {type: :string},
            qualities: {
              type: :array,
              items: ::V1::Schemas::Vehicles::CraftedSlotQuality,
              description: "A recipe slot left out was filled at the neutral grade, 500"
            }
          },
          additionalProperties: false,
          required: %w[blueprintId blueprintSlug qualities]
        })
      end
    end
  end
end
