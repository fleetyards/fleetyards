# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class BlueprintQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              scKeyCont: {type: :string},
              slugCont: {type: :string},
              idIn: {type: :array, items: {type: :string, format: :uuid}},
              nameIn: {type: :array, items: {type: :string}},

              # Which catalogue the output is in. Filtered on the column rather
              # than through the association: ransack cannot compute the class
              # of a polymorphic one and raises the moment a query touches it.
              craftableTypeEq: ::Shared::V1::Schemas::Enums::BlueprintCraftableTypeEnum,
              craftableTypeIn: {type: :array, items: ::Shared::V1::Schemas::Enums::BlueprintCraftableTypeEnum},
              craftableIdEq: {type: :string, format: :uuid},

              # Seconds.
              craftTimeLteq: {type: :integer},
              craftTimeGteq: {type: :integer},

              # The org whose missions hand the recipe out, by name.
              fromOrg: {type: :string},

              # Recipes that consume a material, by the commodity's slug.
              consumingCommodity: {type: :string},
              consumingCommodityIn: {type: :array, items: {type: :string}},

              # Whether the export says where the recipe comes from at all, and
              # whether its output resolved to a catalogue row. Both read by the
              # controller rather than applied through ransack, which skips a
              # scope whose value is false -- and false is the interesting half
              # of both questions.
              withKnownSource: {type: :boolean},
              withCraftable: {type: :boolean},

              # Defaulted off here, where the public list defaults it on: the
              # admin list has to show a recipe the current build dropped.
              currentVersion: {type: :boolean},

              s: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::BlueprintSortEnum
              }, ::Admin::V1::Schemas::Sorts::BlueprintSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::BlueprintSortEnum
              }, ::Admin::V1::Schemas::Sorts::BlueprintSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
