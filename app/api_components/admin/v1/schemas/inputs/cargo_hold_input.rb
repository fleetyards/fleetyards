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
              offsetX: {type: :number, nullable: true},
              offsetY: {type: :number, nullable: true},
              offsetZ: {type: :number, nullable: true},
              rotation: {type: :integer, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
