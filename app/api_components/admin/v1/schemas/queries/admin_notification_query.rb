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
              notificationTypeEq: ::Admin::V1::Schemas::Enums::AdminNotificationTypeEnum,
              severityEq: ::Admin::V1::Schemas::Enums::AdminNotificationSeverityEnum,
              readAtNull: {type: :boolean},
              archivedAtNull: {type: :boolean},
              searchCont: {type: :string},
              s: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::AdminNotificationSortEnum
              }, ::Admin::V1::Schemas::Sorts::AdminNotificationSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::AdminNotificationSortEnum
              }, ::Admin::V1::Schemas::Sorts::AdminNotificationSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
