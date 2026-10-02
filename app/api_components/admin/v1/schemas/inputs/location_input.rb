# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class LocationInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              image: {type: [:string, :null]},
              color: {type: [:string, :null], pattern: "^#[0-9a-fA-F]{6}$"}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
