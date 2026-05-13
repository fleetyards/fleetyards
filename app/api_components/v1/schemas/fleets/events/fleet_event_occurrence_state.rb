# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventOccurrenceState
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetEventId: {type: :string, format: :uuid},
              occurrenceDate: {type: :string, format: :date},
              status: {type: :string, nullable: true},
              lockedAt: {type: :string, format: "date-time", nullable: true},
              startingSoonNotifiedAt: {type: :string, format: "date-time", nullable: true},
              cancelledAt: {type: :string, format: "date-time", nullable: true},
              cancelledReason: {type: :string, nullable: true},
              discordEventId: {type: :string, nullable: true},
              discordSyncedAt: {type: :string, format: "date-time", nullable: true},
              title: {type: :string, nullable: true},
              description: {type: :string, nullable: true},
              briefing: {type: :string, nullable: true},
              location: {type: :string, nullable: true},
              meetupLocation: {type: :string, nullable: true},
              scenario: {type: :string, nullable: true},
              coverImagePreset: {type: :string, nullable: true}
            },
            required: %w[id fleetEventId occurrenceDate]
          })
        end
      end
    end
  end
end
