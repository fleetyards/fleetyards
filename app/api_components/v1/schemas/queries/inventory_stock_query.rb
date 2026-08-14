# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class InventoryStockQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            vehicleIdEq: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
