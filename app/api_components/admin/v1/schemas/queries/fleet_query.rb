# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class FleetQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              fidCont: {type: :string},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::FleetSortEnum
              }, ::Admin::V1::Schemas::Sorts::FleetSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
