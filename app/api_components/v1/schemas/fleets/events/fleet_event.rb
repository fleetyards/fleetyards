# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEvent
          include OpenapiRuby::Components::Base

          STATUSES = %w[draft open locked active completed cancelled].freeze
          VISIBILITIES = %w[members officers fleet].freeze
          SIGNUP_APPROVALS = %w[direct confirmation_required].freeze
          VIEWER_EVENT_ROLES = %w[creator admin moderator].freeze

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
              status: {type: :string, enum: STATUSES},
              startsAt: {type: :string, format: "date-time"},
              endsAt: {type: :string, format: "date-time"},
              timezone: {type: :string},
              location: {type: :string},
              meetupLocation: {type: :string},
              visibility: {type: :string, enum: VISIBILITIES},
              category: {
                type: :string,
                enum: V1::Schemas::Fleets::Missions::Mission::CATEGORIES
              },
              scenario: {type: :string},
              coverImagePreset: {type: :string},
              coverImage: {"$ref": "#/components/schemas/MediaFile"},
              maxAttendees: {type: :integer},
              autoLockEnabled: {type: :boolean},
              autoLockMinutesBefore: {type: :integer},
              cancelledReason: {type: :string},
              signupApproval: {type: :string, enum: SIGNUP_APPROVALS},
              viewerEventRole: {
                type: :string,
                                enum: VIEWER_EVENT_ROLES
              },
              archived: {type: :boolean},
              archivedAt: {type: :string, format: "date-time"},
              externalUid: {type: :string, format: :uuid},
              createdBy: {
                type: :object,
                                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                }
              },
              signupsCount: {type: :integer},
              teamCount: {type: :integer},
              past: {type: :boolean},
              signupsOpen: {type: :boolean},
              discordEventId: {type: :string},
              discordSyncedAt: {type: :string, format: "date-time"},
              discordConfigured: {type: :boolean},
              recurring: {type: :boolean},
              recurrenceInterval: {
                type: :string,
                enum: ::FleetEvent::RECURRENCE_INTERVALS,
                
              },
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
