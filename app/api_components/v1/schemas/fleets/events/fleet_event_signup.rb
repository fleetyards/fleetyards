# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventSignup
          include OpenapiRuby::Components::Base

          STATUSES = %w[confirmed tentative interested pending withdrawn].freeze

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetEventId: {type: :string, format: :uuid},
              fleetEventSlotId: {type: :string, format: :uuid},
              occurrenceDate: {type: :string, format: :date},
              status: {type: :string, enum: STATUSES},
              notes: {type: :string},
              confirmedAt: {type: :string, format: "date-time"},
              withdrawnAt: {type: :string, format: "date-time"},
              user: {
                type: :object,
                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                }
              },
              vehicle: {
                type: :object,
                properties: {
                  id: {type: :string, format: :uuid},
                  name: {type: :string},
                  model: {
                    type: :object,
                    properties: {
                      id: {type: :string, format: :uuid},
                      name: {type: :string},
                      slug: {type: :string},
                      classification: {type: :string},
                      focus: {type: :string},
                      size: {type: :string},
                      minCrew: {type: :integer},
                      maxCrew: {type: :integer},
                      cargo: {type: :integer},
                      positionCount: {type: :integer}
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
