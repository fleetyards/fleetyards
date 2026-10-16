# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # One kind of weapon rack a ship's rooms hold, and how many of it.
      class WeaponRack
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            key: {type: :string},
            count: {type: :integer},
            slots: {type: :array, items: ::Shared::V1::Schemas::WeaponRackSlot}
          },
          additionalProperties: false,
          required: %w[key count slots]
        })
      end
    end
  end
end
