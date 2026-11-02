# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class OutfitUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, maxLength: 100},
            items: {type: :array, items: ::V1::Schemas::Inputs::OutfitItemInput, description: "Everything the outfit wears; a slot left out is emptied"},
            heldWeapon: ::V1::Schemas::Enums::NullableOutfitWeaponSlotEnum,
            body: ::V1::Schemas::Enums::OutfitBodyEnum
          },
          additionalProperties: false
        })
      end
    end
  end
end
