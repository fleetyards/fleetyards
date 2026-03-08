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
              modelIdEq: {type: :string, format: :uuid}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
