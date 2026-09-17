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
            missionName: {type: [:string, :null]},

            # The reputation band the mission is offered in.
            minStanding: {type: [:string, :null]},
            maxStanding: {type: [:string, :null]},

            # Scenario only: the progress points that unlock the tier.
            minPoints: {type: [:integer, :null]},

            poolKey: {type: [:string, :null]},
            poolGroup: {type: [:string, :null]}
          },
          additionalProperties: false,
          required: %w[kind]
        })
      end
    end
  end
end
