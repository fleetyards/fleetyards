# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: [:string, :null]},
            briefing: {type: [:string, :null]},
            startsAt: {type: :string, format: "date-time"},
            endsAt: {type: [:string, :null], format: "date-time"},
            timezone: {type: :string},
            location: {type: [:string, :null]},
            meetupLocation: {type: [:string, :null]},
            visibility: ::V1::Schemas::Enums::FleetEventVisibilityEnum,
            category: ::V1::Schemas::Enums::MissionCategoryEnum,
            scenario: {type: [:string, :null]},
            coverImagePreset: {type: [:string, :null]},
            coverImage: {type: [:string, :null]},
            maxAttendees: {type: [:integer, :null]},
            autoLockEnabled: {type: :boolean},
            autoLockMinutesBefore: {type: [:integer, :null]},
            cancelledReason: {type: [:string, :null]},
            signupApproval: ::V1::Schemas::Enums::FleetEventSignupApprovalEnum,
            recurring: {type: :boolean},
            recurrenceInterval: ::V1::Schemas::Enums::NullableFleetEventRecurrenceIntervalEnum,
            recurrenceUntil: {type: [:string, :null], format: :date},
            recurrenceCount: {type: [:integer, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
