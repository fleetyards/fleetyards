# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ShopCommodityQuery
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              search: {type: :string},
              confirmed: {type: :boolean},
              name: {type: :array, items: {type: :string}},
              manufacturerSlug: {type: :array, items: {type: :string}},
              category: {type: :array, items: {type: :string}},
              subCategory: {type: :array, items: {type: :string}},
              componentItemType: {type: :array, items: {type: :string}},
              equipmentItemType: {type: :array, items: {type: :string}},
              equipmentType: {type: :array, items: {type: :string}},
              equipmentSlot: {type: :array, items: {type: :string}}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
