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
            kind: {type: :string, enum: ::BlueprintSource::KINDS},

            # Null where the generator names more than one faction: a wrong org
            # is worse than none when this is the whole question.
            orgName: {type: :string, nullable: true},
            missionName: {type: :string, nullable: true},

            # The reputation band the mission is offered in.
            minStanding: {type: :string, nullable: true},
            maxStanding: {type: :string, nullable: true},

            # Scenario only: the progress points that unlock the tier.
            minPoints: {type: :integer, nullable: true},

            poolKey: {type: :string, nullable: true},
            poolGroup: {type: :string, nullable: true}
          },
          additionalProperties: false,
          required: %w[kind]
        })
      end
    end
  end
end
