# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class FuelTank
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            capacity: {type: :number}
          },
          additionalProperties: false,
          required: %w[capacity]
        })
      end
    end
  end
end
