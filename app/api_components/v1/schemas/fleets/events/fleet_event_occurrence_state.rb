# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventOccurrenceState
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetEventId: {type: :string, format: :uuid},
              occurrenceDate: {type: :string, format: :date},
              status: {type: :string},
              lockedAt: {type: :string, format: "date-time"},
              startingSoonNotifiedAt: {type: :string, format: "date-time"},
              cancelledAt: {type: :string, format: "date-time"},
              cancelledReason: {type: :string},
              discordEventId: {type: :string},
              discordSyncedAt: {type: :string, format: "date-time"},
              title: {type: :string},
              description: {type: :string},
              briefing: {type: :string},
              location: {type: :string},
              meetupLocation: {type: :string},
              scenario: {type: :string},
              coverImagePreset: {type: :string}
            },
            required: %w[id fleetEventId occurrenceDate]
          })
        end
      end
    end
  end
end
