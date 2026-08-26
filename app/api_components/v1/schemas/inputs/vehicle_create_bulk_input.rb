# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleCreateBulkInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            vehicles: {
              type: :array,
              items: VehicleCreateBulkItemInput
            }
          },
          additionalProperties: false,
          required: %w[vehicles]
        })
      end
    end
  end
end
