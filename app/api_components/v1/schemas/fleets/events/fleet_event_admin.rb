# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventAdmin
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              fleetEventId: {type: :string, format: :uuid},
              role: {"$ref": "#/components/schemas/FleetEventAdminRoleEnum"},
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
