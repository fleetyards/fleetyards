# frozen_string_literal: true

module V1
  module Schemas
    # The shops at a place, from UEX: the game files carry none.
    class LocationShops
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          shops: {type: :array, items: ::V1::Schemas::LocationShop}
        },
        additionalProperties: false,
        required: %w[shops]
      })
    end
  end
end
