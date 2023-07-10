# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleBulkDestroyInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            ids: {type: :array, items: {type: :string, format: :uuid}}
          },
          additionalProperties: false,
          required: %w[ids]
        })
      end
    end
  end
end
