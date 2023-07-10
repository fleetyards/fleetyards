# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class RsiHangarItemInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            customName: {type: :string, nullable: true},
            type: {"$ref": "#/components/schemas/RsiHangarItemKindEnum"}
          },
          additionalProperties: false,
          required: %w[id name type]
        })
      end
    end
  end
end
