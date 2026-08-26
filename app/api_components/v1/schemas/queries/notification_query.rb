# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class NotificationQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            notificationTypeEq: {"$ref": "#/components/schemas/NotificationTypeEnum"},
            readAtNull: {type: :boolean},
            sorts: {anyOf: [{
              type: :array, items: {"$ref": "#/components/schemas/NotificationSortEnum"}
            }, {
              "$ref": "#/components/schemas/NotificationSortEnum"
            }]}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
