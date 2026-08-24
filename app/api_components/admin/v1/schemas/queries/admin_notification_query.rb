# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class AdminNotificationQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              notificationTypeEq: {"$ref": "#/components/schemas/AdminNotificationTypeEnum"},
              severityEq: {"$ref": "#/components/schemas/AdminNotificationSeverityEnum"},
              readAtNull: {type: :boolean},
              archivedAtNull: {type: :boolean},
              searchCont: {type: :string},
              sorts: {anyOf: [{
                type: :array, items: {"$ref": "#/components/schemas/AdminNotificationSortEnum"}
              }, {
                "$ref": "#/components/schemas/AdminNotificationSortEnum"
              }]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
