# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Sales
        class ModelSales
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              sales: {type: :array, items: {"$ref": "#/components/schemas/ModelSale"}},
              salesCount: {type: :integer},
              lastSaleAt: {type: [:string, :null], format: :"date-time"},
              # Null until a second sale gives the first one a gap to measure.
              averageDaysBetweenSales: {type: [:number, :null]}
            },
            required: %i[sales salesCount],
            additionalProperties: false
          })
        end
      end
    end
  end
end
