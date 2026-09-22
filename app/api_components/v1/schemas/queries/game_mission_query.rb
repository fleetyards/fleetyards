# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class GameMissionQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            idIn: {type: :array, items: {type: :string, format: :uuid}},
            nameIn: {type: :array, items: {type: :string}},

            kindEq: ::Shared::V1::Schemas::Enums::GameMissionKindEnum,
            kindIn: {type: :array, items: ::Shared::V1::Schemas::Enums::GameMissionKindEnum},

            # The org offering the work. `fromOrg` takes the reputation record's
            # key and is applied by the controller against the build; `orgNameEq`
            # matches the display name, which is localised and is what a text
            # filter has to hand.
            fromOrg: {type: :string},
            orgNameEq: {type: :string},
            orgNameIn: {type: :array, items: {type: :string}},

            # Which side of the law the org sits on, without having to know the
            # orgs by name.
            alignmentEq: ::Shared::V1::Schemas::Enums::NullableBlueprintSourceAlignmentEnum,
            alignmentIn: {
              type: :array, items: ::Shared::V1::Schemas::Enums::BlueprintSourceAlignmentEnum
            },

            # The band the mission is offered in. Strings rather than an enum:
            # the export declares 380 standing records and states no rank order
            # anywhere a parse can read, so the options come from
            # `/filters/missions/standings` instead.
            minStandingEq: {type: :string},
            minStandingIn: {type: :array, items: {type: :string}},
            maxStandingEq: {type: :string},

            # Each axis is a 1-7 as the game's own designers rated it.
            difficultyMechanicalSkillLteq: {type: :integer},
            difficultyMechanicalSkillGteq: {type: :integer},
            difficultyRiskOfLossLteq: {type: :integer},
            difficultyRiskOfLossGteq: {type: :integer},

            # What the mission pays. Several mean "pays any of these".
            rewarding: ::Shared::V1::Schemas::Enums::GameMissionRewardFilterEnum,
            rewardingIn: {
              type: :array, items: ::Shared::V1::Schemas::Enums::GameMissionRewardFilterEnum
            },

            # Whether the build is offering it at all. Read by the controller
            # rather than applied through ransack, which skips a scope whose
            # value is false and would answer "what is not released" with the
            # whole catalogue.
            released: {type: :boolean},

            currentVersion: {type: :boolean},
            s: ::V1::Schemas::Enums::GameMissionSortingEnum,
            sorts: {type: :array, items: ::V1::Schemas::Enums::GameMissionSortingEnum}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
