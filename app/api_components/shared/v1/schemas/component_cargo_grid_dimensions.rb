# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentCargoGridDimensions
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            x: {type: :number},
            y: {type: :number},
            z: {type: :number},
            scu: {type: :number},
            maxContainerSize: {"$ref": "#/components/schemas/ComponentCargoGridContainer"}
          },
          additionalProperties: false,
          required: %w[x y z scu maxContainerSize]
        })
      end
    end
  end
end
