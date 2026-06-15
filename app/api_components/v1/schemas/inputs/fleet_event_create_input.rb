# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            missionSlug: {type: [:string, :null]},
            title: {type: :string},
            description: {type: [:string, :null]},
            briefing: {type: [:string, :null]},
            startsAt: {type: :string, format: "date-time"},
            endsAt: {type: [:string, :null], format: "date-time"},
            timezone: {type: :string},
            location: {type: [:string, :null]},
            meetupLocation: {type: [:string, :null]},
            visibility: {
              type: :string,
              enum: V1::Schemas::Fleets::Events::FleetEvent::VISIBILITIES
            },
            category: {
              type: :string,
              enum: V1::Schemas::Fleets::Missions::Mission::CATEGORIES
            },
            scenario: {type: [:string, :null]},
            coverImagePreset: {type: [:string, :null]},
            coverImage: {type: [:string, :null]},
            maxAttendees: {type: [:integer, :null]},
            autoLockEnabled: {type: :boolean},
            autoLockMinutesBefore: {type: [:integer, :null]},
            signupApproval: {
              type: :string,
              enum: V1::Schemas::Fleets::Events::FleetEvent::SIGNUP_APPROVALS
            },
            recurring: {type: :boolean},
            recurrenceInterval: {
              type: [:string, :null],
              enum: ::FleetEvent::RECURRENCE_INTERVALS
            },
            recurrenceUntil: {type: [:string, :null], format: :date},
            recurrenceCount: {type: [:integer, :null]}
          },
          required: %w[title startsAt timezone visibility],
          additionalProperties: false
        })
      end
    end
  end
end
