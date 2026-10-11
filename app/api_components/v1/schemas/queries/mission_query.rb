# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class MissionQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            titleCont: {type: :string},
            statusEq: ::V1::Schemas::Enums::MissionStatusEnum,
            s: {anyOf: [{
              type: :array, items: ::V1::Schemas::Enums::MissionSortEnum
            }, ::V1::Schemas::Enums::MissionSortEnum]}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
