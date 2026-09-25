# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetInventoryQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            visibilityEq: ::V1::Schemas::Enums::FleetInventoryVisibilityEnum,
            s: {type: :string},
            sorts: {type: :string}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
