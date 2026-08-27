# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class SupporterContributionQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              nameEq: {type: :string},
              recurringEq: {type: :boolean},
              anonymousEq: {type: :boolean},
              sourceEq: ::Admin::V1::Schemas::Enums::SupporterContributionSourceEnum,
              startedAtGteq: {type: :string, format: :date},
              startedAtLteq: {type: :string, format: :date},
              endedAtGteq: {type: :string, format: :date},
              endedAtLteq: {type: :string, format: :date},
              userIdEq: {type: :string, format: :uuid},
              userIdNull: {type: :boolean},
              userUsernameCont: {type: :string},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::SupporterContributionSortEnum
              }, ::Admin::V1::Schemas::Sorts::SupporterContributionSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
