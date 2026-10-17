# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadoutItem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slotPath: {type: :string, description: "Hardpoint names from the hull down, joined by /"},
            itemType: ::V1::Schemas::Enums::VehicleLoadoutItemTypeEnum,
            itemId: {type: :string, format: :uuid, description: "Left out on an Empty item, which holds nothing"}
          },
          additionalProperties: false,
          required: %w[slotPath itemType]
        })
      end
    end
  end
end
