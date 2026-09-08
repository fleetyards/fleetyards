# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class AdminHardpointQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              parentIdEq: {type: :string, format: :uuid},
              parentTypeEq: {type: :string},
              sourceEq: ::Shared::V1::Schemas::Enums::HardpointSourceEnum,
              groupEq: ::Shared::V1::Schemas::Enums::HardpointGroupEnum,
              categoryEq: ::Shared::V1::Schemas::Enums::HardpointCategoryEnum,
              componentIdEq: {type: :string, format: :uuid},
              scNameCont: {type: :string}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
