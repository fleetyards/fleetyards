# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleLoadoutItemInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slotPath: {type: :string, description: "Hardpoint names from the hull down, joined by /"},
            itemType: ::V1::Schemas::Enums::VehicleLoadoutItemTypeEnum,
            itemId: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: %w[slotPath itemType itemId]
        })
      end
    end
  end
end
