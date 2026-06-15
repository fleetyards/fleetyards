# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            missionSlug: {type: :string},
            title: {type: :string},
            description: {type: :string},
            briefing: {type: :string},
            startsAt: {type: :string, format: "date-time"},
            endsAt: {type: :string, format: "date-time"},
            timezone: {type: :string},
            location: {type: :string},
            meetupLocation: {type: :string},
            visibility: {
              type: :string,
              enum: V1::Schemas::Fleets::Events::FleetEvent::VISIBILITIES
            },
            category: {
              type: :string,
              enum: V1::Schemas::Fleets::Missions::Mission::CATEGORIES
            },
            scenario: {type: :string},
            coverImagePreset: {type: :string},
            coverImage: {type: :string},
            maxAttendees: {type: :integer},
            autoLockEnabled: {type: :boolean},
            autoLockMinutesBefore: {type: :integer},
            signupApproval: {
              type: :string,
              enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS
            },
            recurring: {type: :boolean},
            recurrenceInterval: {
              type: :string,
              enum: ::FleetEvent::RECURRENCE_INTERVALS,
              
            },
            recurrenceUntil: {type: :string, format: :date},
            recurrenceCount: {type: :integer}
          },
          required: %w[title startsAt timezone visibility],
          additionalProperties: false
        })
      end
    end
  end
end
