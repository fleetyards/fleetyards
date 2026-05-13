# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventAdmin
          include Rswag::SchemaComponents::Component

          ROLES = %w[admin moderator].freeze

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetEventId: {type: :string, format: :uuid},
              role: {type: :string, enum: ROLES},
              createdAt: {type: :string, format: "date-time"},
              user: {
                type: :object,
                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                },
                required: %w[id username]
              },
              grantedBy: {
                type: :object,
                nullable: true,
                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                }
              }
            },
            required: %w[id fleetEventId role user createdAt],
            additionalProperties: false
          })
        end
      end
    end
  end
end
