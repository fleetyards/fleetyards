# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class CargoHoldQuery
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              parentTypeEq: {type: :string},
              parentIdEq: {type: :string, format: :uuid}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
