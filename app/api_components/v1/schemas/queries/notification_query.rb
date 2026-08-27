# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class NotificationQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            notificationTypeEq: ::V1::Schemas::Enums::NotificationTypeEnum,
            readAtNull: {type: :boolean},
            sorts: {anyOf: [{
              type: :array, items: ::V1::Schemas::Sorts::NotificationSortEnum
            }, ::V1::Schemas::Sorts::NotificationSortEnum]}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
