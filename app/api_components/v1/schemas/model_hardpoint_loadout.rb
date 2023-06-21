# frozen_string_literal: true

module V1
  module Schemas
    class ModelHardpointLoadout
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          component: {"$ref": "#/components/schemas/Component", nullable: true},
          name: {type: :string}
        },
        required: %w[id name]
      })
    end
  end
end
