# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleLoadoutInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: [:string, :null]},
            url: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
