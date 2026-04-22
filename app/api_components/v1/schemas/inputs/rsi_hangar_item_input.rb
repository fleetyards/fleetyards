# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class RsiHangarItemInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string},
            name: {type: :string},
            customName: {type: :string},
            type: {"$ref": "#/components/schemas/RsiHangarItemKindEnum"},
            image: {type: :string, format: :uri}
          },
          additionalProperties: false,
          required: %w[id name type]
        })
      end
    end
  end
end
