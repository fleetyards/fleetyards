# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class AnnouncementQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              searchCont: {type: :string},
              statusEq: ::Admin::V1::Schemas::Enums::AnnouncementStatusEnum,
              s: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::AnnouncementSortEnum
              }, ::Admin::V1::Schemas::Sorts::AnnouncementSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::AnnouncementSortEnum
              }, ::Admin::V1::Schemas::Sorts::AnnouncementSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
