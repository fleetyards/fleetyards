# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Prices
        # One recorded change to a ship's pledge price.
        #
        # `from` is null where the ship was first given a price and `to` is null
        # where one was taken away. Neither is a price movement.
        class ModelPricePoint
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              changedAt: {type: :string, format: :"date-time"},
              from: {type: [:number, :null]},
              to: {type: [:number, :null]}
            },
            required: %i[changedAt],
            additionalProperties: false
          })
        end
      end
    end
  end
end
