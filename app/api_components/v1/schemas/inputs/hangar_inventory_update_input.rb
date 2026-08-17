# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarInventoryUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            description: {type: [:string, :null]},
            location: {type: [:string, :null]},
            image: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
