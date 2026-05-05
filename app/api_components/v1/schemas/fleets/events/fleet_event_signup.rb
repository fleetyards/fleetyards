# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventSignup
          include Rswag::SchemaComponents::Component

          STATUSES = %w[confirmed tentative interested pending withdrawn].freeze

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetEventId: {type: :string, format: :uuid},
              fleetEventSlotId: {type: :string, format: :uuid, nullable: true},
              status: {type: :string, enum: STATUSES},
              notes: {type: :string, nullable: true},
              confirmedAt: {type: :string, format: "date-time", nullable: true},
              withdrawnAt: {type: :string, format: "date-time", nullable: true},
              user: {
                type: :object,
                nullable: true,
                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                }
              },
              vehicle: {
                type: :object,
                nullable: true,
                properties: {
                  id: {type: :string, format: :uuid},
                  name: {type: :string, nullable: true},
                  model: {
                    type: :object,
                    nullable: true,
                    properties: {
                      id: {type: :string, format: :uuid},
                      name: {type: :string},
                      slug: {type: :string}
                    }
                  }
                }
              }
            },
            required: %w[id fleetEventId status],
            additionalProperties: false
          })
        end
      end
    end
  end
end
