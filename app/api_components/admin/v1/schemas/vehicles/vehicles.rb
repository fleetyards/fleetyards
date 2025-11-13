# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Vehicles
        class Vehicles < ::Shared::V1::Schemas::BaseList
          include Rswag::SchemaComponents::Component

          schema({
            properties: {
              items: {type: :array, items: {"$ref": "#/components/schemas/Vehicle"}}
            },
            required: %w[items]
          })
        end
      end
    end
  end
end
