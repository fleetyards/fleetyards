# frozen_string_literal: true

module V1
  module Schemas
    module Loadouts
      # A saved item the build in force no longer accepts, and why.
      class LoadoutItemProblem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slotPath: {type: :string},
            itemType: ::V1::Schemas::Enums::VehicleLoadoutItemTypeEnum,
            itemId: {type: :string, format: :uuid},
            itemName: {type: :string},
            code: ::V1::Schemas::Enums::VehicleLoadoutItemProblemEnum
          },
          additionalProperties: false,
          required: %w[slotPath itemType code]
        })
      end
    end
  end
end
