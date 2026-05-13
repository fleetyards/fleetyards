# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventUpdateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
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
            autoLockMinutesBefore: {type: :integer, nullable: true},
            cancelledReason: {type: :string, nullable: true},
            signupApproval: {
              type: :string,
              enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS
            },
            recurring: {type: :boolean},
            recurrenceInterval: {
              type: :string,
              enum: ::FleetEvent::RECURRENCE_INTERVALS,
              nullable: true
            },
            recurrenceUntil: {type: :string, format: :date, nullable: true},
            recurrenceCount: {type: :integer, nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
