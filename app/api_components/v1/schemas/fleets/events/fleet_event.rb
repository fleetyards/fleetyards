# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEvent
          include Rswag::SchemaComponents::Component

          STATUSES = %w[draft open locked active completed cancelled].freeze
          VISIBILITIES = %w[members officers fleet].freeze
          SIGNUP_APPROVALS = %w[direct confirmation_required].freeze
          VIEWER_EVENT_ROLES = %w[creator admin moderator].freeze

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetId: {type: :string, format: :uuid},
              missionId: {type: :string, format: :uuid, nullable: true},
              title: {type: :string},
              slug: {type: :string},
              description: {type: :string, nullable: true},
              briefing: {type: :string, nullable: true},
              status: {type: :string, enum: STATUSES},
              startsAt: {type: :string, format: "date-time"},
              endsAt: {type: :string, format: "date-time", nullable: true},
              timezone: {type: :string},
              location: {type: :string, nullable: true},
              meetupLocation: {type: :string, nullable: true},
              visibility: {type: :string, enum: VISIBILITIES},
              category: {
                type: :string,
                enum: V1::Schemas::Fleets::Missions::Mission::CATEGORIES
              },
              scenario: {type: :string, nullable: true},
              coverImagePreset: {type: :string, nullable: true},
              coverImage: {"$ref": "#/components/schemas/MediaFile", nullable: true},
              maxAttendees: {type: :integer, nullable: true},
              autoLockEnabled: {type: :boolean},
              autoLockMinutesBefore: {type: :integer, nullable: true},
              cancelledReason: {type: :string, nullable: true},
              signupApproval: {type: :string, enum: SIGNUP_APPROVALS},
              viewerEventRole: {
                type: :string,
                nullable: true,
                enum: VIEWER_EVENT_ROLES + [nil]
              },
              archived: {type: :boolean},
              archivedAt: {type: :string, format: "date-time", nullable: true},
              externalUid: {type: :string, format: :uuid},
              createdBy: {
                type: :object,
                nullable: true,
                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                }
              },
              signupsCount: {type: :integer},
              teamCount: {type: :integer},
              past: {type: :boolean},
              signupsOpen: {type: :boolean},
              discordEventId: {type: :string, nullable: true},
              discordSyncedAt: {type: :string, format: "date-time", nullable: true},
              discordConfigured: {type: :boolean},
              recurring: {type: :boolean},
              recurrenceInterval: {
                type: :string,
                enum: ::FleetEvent::RECURRENCE_INTERVALS,
                nullable: true
              },
              recurrenceUntil: {type: :string, format: :date, nullable: true},
              recurrenceCount: {type: :integer, nullable: true},
              excludedDates: {
                type: :array,
                items: {type: :string, format: :date}
              },
              occurrenceDate: {type: :string, format: :date, nullable: true},
              parentEventSlug: {type: :string, nullable: true},
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
