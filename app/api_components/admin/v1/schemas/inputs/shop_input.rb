# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ShopInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              image: {type: [:string, :null]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
