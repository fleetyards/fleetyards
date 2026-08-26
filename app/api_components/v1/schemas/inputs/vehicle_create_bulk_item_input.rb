# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleCreateBulkItemInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            modelId: {type: :string, format: :uuid},
            wanted: {type: :boolean},
            public: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[modelId]
        })
      end
    end
  end
end
