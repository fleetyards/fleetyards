# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BlueprintSource
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # "contract" is a mission an org offers; "scenario" is XenoThreat
            # handing pools out by progress points instead.
            kind: ::Shared::V1::Schemas::Enums::BlueprintSourceKindEnum,

            # Null where the generator names more than one faction: a wrong org
            # is worse than none when this is the whole question.
            orgName: {type: [:string, :null]},

            # Which side of the law that org sits on, so a player can tell a
            # UEE-side contract from an outlaw one without knowing the org.
            alignment: ::Shared::V1::Schemas::Enums::NullableBlueprintSourceAlignmentEnum,

            missionName: {type: [:string, :null]},

            # The reputation band the mission is offered in.
            minStanding: {type: [:string, :null]},
            maxStanding: {type: [:string, :null]},

            # Scenario only: the progress points that unlock the tier.
            minPoints: {type: [:integer, :null]},

            poolKey: {type: [:string, :null]},
            poolGroup: {type: [:string, :null]},

            # The contracts behind a contract source. One source can stand for
            # several: the same contract offered in several systems, or in two
            # regions of one, is a mission of its own each time. Empty for a
            # scenario.
            missions: {type: :array, items: ::Shared::V1::Schemas::BlueprintSourceMission}
          },
          additionalProperties: false,
          required: %w[kind missions]
        })
      end
    end
  end
end
