# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleCreateBulkInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            vehicles: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  modelId: {type: :string, format: :uuid},
                  wanted: {type: :boolean},
                  public: {type: :boolean}
                },
                additionalProperties: false,
                required: %w[modelId]
              }
            }
          },
          additionalProperties: false,
          required: %w[vehicles]
        })
      end
    end
  end
end
