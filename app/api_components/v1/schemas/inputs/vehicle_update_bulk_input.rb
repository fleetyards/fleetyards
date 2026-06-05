# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleUpdateBulkInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            ids: {type: :array, items: {type: :string, format: :uuid}},
            wanted: {type: [:boolean, :null]},
            public: {type: [:boolean, :null]},
            hangarGroupIds: {type: [:array, :null], items: {type: :string, format: :uuid}}
          },
          additionalProperties: false,
          required: %w[ids]
        })
      end
    end
  end
end
