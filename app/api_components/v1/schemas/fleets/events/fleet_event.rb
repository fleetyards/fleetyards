# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEvent
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetId: {type: :string, format: :uuid},
              missionId: {type: :string, format: :uuid},
              title: {type: :string},
              slug: {type: :string},
              description: {type: :string},
              briefing: {type: :string},
              status: {"$ref": "#/components/schemas/FleetEventStatusEnum"},
              startsAt: {type: :string, format: "date-time"},
              endsAt: {type: :string, format: "date-time"},
              timezone: {type: :string},
              location: {type: :string},
              meetupLocation: {type: :string},
              visibility: {"$ref": "#/components/schemas/FleetEventVisibilityEnum"},
              category: {"$ref": "#/components/schemas/MissionCategoryEnum"},
              scenario: {type: :string},
              coverImagePreset: {type: :string},
              coverImage: {"$ref": "#/components/schemas/MediaFile"},
              maxAttendees: {type: :integer},
              autoLockEnabled: {type: :boolean},
              autoLockMinutesBefore: {type: :integer},
              cancelledReason: {type: :string},
              signupApproval: {"$ref": "#/components/schemas/FleetEventSignupApprovalEnum"},
              viewerEventRole: {"$ref": "#/components/schemas/FleetEventViewerRoleEnum"},
              archived: {type: :boolean},
              archivedAt: {type: :string, format: "date-time"},
              externalUid: {type: :string, format: :uuid},
              createdBy: Shared::V1::Schemas::UserRef,
              signupsCount: {type: :integer},
              teamCount: {type: :integer},
              past: {type: :boolean},
              signupsOpen: {type: :boolean},
              discordEventId: {type: :string},
              discordSyncedAt: {type: :string, format: "date-time"},
              discordConfigured: {type: :boolean},
              recurring: {type: :boolean},
              recurrenceInterval: {"$ref": "#/components/schemas/FleetEventRecurrenceIntervalEnum"},
              recurrenceUntil: {type: :string, format: :date},
              recurrenceCount: {type: :integer},
              excludedDates: {
                type: :array,
                items: {type: :string, format: :date}
              },
              occurrenceDate: {type: :string, format: :date},
              parentEventSlug: {type: :string},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            required: %w[
              id fleetId title slug status startsAt timezone visibility category
              autoLockEnabled archived externalUid signupApproval signupsCount teamCount past signupsOpen discordConfigured createdAt updatedAt
            ]
          })
        end
      end
    end
  end
end
