# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentCargoGridContainer
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            size: {type: :number},
            x: {type: :number},
            y: {type: :number},
            z: {type: :number}
          },
          additionalProperties: false,
          required: %w[size x y z]
        })
      end
    end
  end
end
