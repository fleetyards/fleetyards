# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module CargoHolds
          class AdminCargoHolds < ::Shared::V1::Schemas::BaseList
            include Rswag::SchemaComponents::Component

            schema({
              properties: {
                items: {type: :array, items: {"$ref": "#/components/schemas/AdminCargoHold"}}
              },
              required: %w[items]
            })
          end
        end
      end
    end
  end
end
