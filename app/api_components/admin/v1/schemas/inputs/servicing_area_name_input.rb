# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        # A list rather than a map by key: the API rewrites the keys of an
        # object between camel and snake case, and an area's key is not a name
        # it may touch.
        class ServicingAreaNameInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              key: {type: :string},
              name: {type: [:string, :null]}
            },
            additionalProperties: false,
            required: %w[key]
          })
        end
      end
    end
  end
end
