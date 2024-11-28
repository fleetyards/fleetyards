# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Dimension
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            x: {type: :number},
            y: {type: :number},
            z: {type: :number},
            scu: {type: :number}
          },
          additionalProperties: false,
          required: %w[x y z scu]
        })
      end
    end
  end
end
