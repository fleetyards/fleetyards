# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class CargoHoldInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              offsetX: {type: [:number, :null]},
              offsetY: {type: [:number, :null]},
              offsetZ: {type: [:number, :null]},
              rotation: {type: [:integer, :null]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
