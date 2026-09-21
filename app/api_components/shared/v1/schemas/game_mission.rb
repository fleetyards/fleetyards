# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class GameMission
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},

            # As the export writes it, `~mission(TargetName)` spans and all --
            # the game fills those in from the mission it generates, and 902 of
            # the 2472 titles carry one. Null for the 64 contracts that have
            # never been titled.
            name: {type: [:string, :null]},
            slug: {type: :string},

            # `<generator>_<debugName>`, flattened. Neither half is unique
            # alone; together they leave 13 pairs, and those take the head of
            # their GUID.
            scKey: {type: :string},
            scRef: {type: :string},

            kind: ::Shared::V1::Schemas::Enums::GameMissionKindEnum,

            retired: {type: :boolean},

            # Whether the build offers it at all. False for the 349 contracts
            # flagged `notForRelease` or `workInProgress` -- in the files, in
            # front of nobody.
            released: {type: :boolean},

            # Null on 197: a handler naming no faction takes its generator's
            # org, and only where that generator names exactly one.
            org: {anyOf: [::Shared::V1::Schemas::GameMissionOrg, {type: :null}]},

            # The reputation band it is offered in, which is what a player reads
            # as VHRT and up. Strings rather than an enum: the export states 380
            # standing records and no rank order a parse can read.
            minStanding: {type: [:string, :null]},
            maxStanding: {type: [:string, :null]},

            difficulty: {
              anyOf: [::Shared::V1::Schemas::GameMissionDifficulty, {type: :null}]
            },

            # What kinds of thing it pays, for a row with no space for amounts.
            rewardKinds: {
              type: :array, items: ::Shared::V1::Schemas::Enums::GameMissionRewardFilterEnum
            },

            # Detail responses only -- a list omits all four rather than paying
            # for them per row, which is why none of them is required.
            #
            # The description runs to 1,200 characters on the longest, and 2344
            # of the 2475 carry a run-time span; it also carries the game's own
            # `<EM4>` emphasis markup.
            description: {type: [:string, :null]},
            rewards: {type: :array, items: ::Shared::V1::Schemas::GameMissionReward},

            # The recipes this mission hands out, through the reward pools it
            # names. 786 of the 2,536 contracts hand one out.
            #
            # The reverse -- a blueprint naming the missions that drop it --
            # already exists as text on `BlueprintSource#missionName`, and
            # stays text until that table points at a mission rather than
            # carrying its own copy of the name.
            blueprints: {type: :array, items: ::Shared::V1::Schemas::GameMissionBlueprint},

            # Where in the export it came from. `debugName` is a developer's
            # note and not for reading -- carried because it is what makes a row
            # findable in the game files again.
            generatorKey: {type: [:string, :null]},
            debugName: {type: [:string, :null]},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id slug scKey scRef retired released rewardKinds createdAt updatedAt]
        })
      end
    end
  end
end
