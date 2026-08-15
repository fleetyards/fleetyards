# frozen_string_literal: true

module V1
  module Schemas
    class Commodity
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          commodityType: {type: [:string, :null]},
          description: {type: [:string, :null]},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name slug createdAt updatedAt]
      })
    end
  end
end
