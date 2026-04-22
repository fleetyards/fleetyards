# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Hardpoints
        class ModelHardpointLoadout
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              component: {"$ref": "#/components/schemas/Component"},
              name: {type: :string}
            },
            additionalProperties: false,
            required: %w[id name]
          })
        end
      end
    end
  end
end
