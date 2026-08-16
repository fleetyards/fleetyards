# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetInventoryItemQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            nameEq: {type: :string},
            unitEq: {type: :string, enum: %w[scu units]},
            categoryEq: {type: :string, enum: %w[commodity component weapon equipment ammunition consumable other]},
            qualityGteq: {type: :integer},
            qualityLteq: {type: :integer},
            sorts: {type: :string}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
