# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetSquadronQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            s: {anyOf: [{
              type: :array, items: ::V1::Schemas::Enums::FleetSquadronSortEnum
            }, ::V1::Schemas::Enums::FleetSquadronSortEnum]}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
