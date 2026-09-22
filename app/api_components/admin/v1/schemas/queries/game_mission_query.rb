# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class GameMissionQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              scKeyCont: {type: :string},
              slugCont: {type: :string},

              # A developer's note rather than a name, and searchable for
              # exactly that reason: it is how a row is found again in the
              # export when its title is a run-time template or absent.
              debugNameCont: {type: :string},
              generatorKeyEq: {type: :string},

              idIn: {type: :array, items: {type: :string, format: :uuid}},
              nameIn: {type: :array, items: {type: :string}},

              kindEq: ::Shared::V1::Schemas::Enums::GameMissionKindEnum,
              kindIn: {type: :array, items: ::Shared::V1::Schemas::Enums::GameMissionKindEnum},

              fromOrg: {type: :string},
              orgNameEq: {type: :string},
              orgNameIn: {type: :array, items: {type: :string}},

              alignmentEq: ::Shared::V1::Schemas::Enums::NullableBlueprintSourceAlignmentEnum,
              alignmentIn: {
                type: :array, items: ::Shared::V1::Schemas::Enums::BlueprintSourceAlignmentEnum
              },

              minStandingEq: {type: :string},
              minStandingIn: {type: :array, items: {type: :string}},

              rewarding: ::Shared::V1::Schemas::Enums::GameMissionRewardFilterEnum,
              rewardingIn: {
                type: :array, items: ::Shared::V1::Schemas::Enums::GameMissionRewardFilterEnum
              },

              # Read by the controller rather than through ransack, which skips
              # a scope whose value is false -- so `released=false` asked that
              # way would answer with the whole catalogue.
              released: {type: :boolean},

              # The 74 contracts the game never named, which the public
              # catalogue leaves out entirely. Admin only, because "what did
              # this load bring in that nobody can read" is a question only this
              # section asks.
              named: {type: :boolean},

              # Defaulted false here where the public list defaults it true: the
              # admin list has to show what the current build dropped.
              currentVersion: {type: :boolean},
              s: ::Admin::V1::Schemas::Sorts::GameMissionSortEnum,
              sorts: {type: :array, items: ::Admin::V1::Schemas::Sorts::GameMissionSortEnum}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
