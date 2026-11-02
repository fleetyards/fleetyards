# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class OutfitItemInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slot: ::V1::Schemas::Enums::OutfitSlotEnum,
            equipmentId: {type: :string, format: :uuid}
          },
          required: %w[slot equipmentId],
          additionalProperties: false
        })
      end
    end
  end
end
