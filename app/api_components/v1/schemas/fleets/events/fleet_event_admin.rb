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
              role: ::V1::Schemas::Enums::FleetEventAdminRoleEnum,
              createdAt: {type: :string, format: "date-time"},
              user: Shared::V1::Schemas::UserRefRequired,
              grantedBy: ::V1::Schemas::UserRef
            },
            required: %w[id fleetEventId role user createdAt],
            additionalProperties: false
          })
        end
      end
    end
  end
end
