# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class HangarPledgeItemQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            upgradeFromModelSlugEq: {type: :string},
            upgradeToModelSlugEq: {type: :string},
            nameCont: {type: :string},
            meltableEq: {type: :boolean},
            withValue: {type: :boolean, description: "Only items whose pledge melts for more than nothing"},
            s: ::V1::Schemas::Enums::HangarPledgeItemSortingEnum,
            sorts: {type: :array, items: ::V1::Schemas::Enums::HangarPledgeItemSortingEnum}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
