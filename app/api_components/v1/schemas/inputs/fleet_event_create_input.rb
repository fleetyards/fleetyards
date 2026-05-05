# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventCreateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            missionSlug: {type: :string, nullable: true},
            title: {type: :string},
            description: {type: :string, nullable: true},
            briefing: {type: :string, nullable: true},
            startsAt: {type: :string, format: "date-time"},
            endsAt: {type: :string, format: "date-time", nullable: true},
            timezone: {type: :string},
            location: {type: :string, nullable: true},
            meetupLocation: {type: :string, nullable: true},
            visibility: {
              type: :string,
              enum: V1::Schemas::Fleets::Events::FleetEvent::VISIBILITIES
            },
            category: {
              type: :string,
              enum: V1::Schemas::Fleets::Missions::Mission::CATEGORIES
            },
            scenario: {type: :string, nullable: true},
            coverImagePreset: {type: :string, nullable: true},
            coverImage: {type: :string, nullable: true},
            maxAttendees: {type: :integer, nullable: true},
            autoLockEnabled: {type: :boolean},
            autoLockMinutesBefore: {type: :integer, nullable: true}
          },
          required: %w[title startsAt timezone visibility],
          additionalProperties: false
        })
      end
    end
  end
end
