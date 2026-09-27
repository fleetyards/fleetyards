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
            visibility: ::V1::Schemas::Enums::FleetEventVisibilityEnum,
            fleetSquadronIds: {type: :array, items: {type: :string, format: :uuid}},
            category: ::V1::Schemas::Enums::MissionCategoryEnum,
            scenario: {type: [:string, :null]},
            coverImagePreset: {type: [:string, :null]},
            coverImage: {type: [:string, :null]},
            maxAttendees: {type: [:integer, :null]},
            autoLockEnabled: {type: :boolean},
            autoLockMinutesBefore: {type: [:integer, :null]},
            signupApproval: ::V1::Schemas::Enums::FleetEventSignupApprovalEnum,
            recurring: {type: :boolean},
            recurrenceInterval: ::V1::Schemas::Enums::NullableFleetEventRecurrenceIntervalEnum,
            recurrenceUntil: {type: [:string, :null], format: :date},
            recurrenceCount: {type: [:integer, :null]},
            recurrenceEvery: {type: :integer, minimum: 1, maximum: ::FleetEvent::MAX_RECURRENCE_EVERY},
            recurrenceWeekdays: {type: :array, items: {type: :integer, minimum: 0, maximum: 6}}
          },
          required: %w[title startsAt timezone visibility],
          additionalProperties: false
        })
      end
    end
  end
end
