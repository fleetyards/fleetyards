# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventExtended
          include OpenapiRuby::Components::Base

          schema({
            allOf: [
              ::V1::Schemas::Fleets::Events::FleetEvent,
              {
                type: :object,
                properties: {
                  teams: {
                    type: :array,
                    items: ::V1::Schemas::Fleets::Events::FleetEventTeam
                  },
                  unassignedSignups: {
                    type: :array,
                    items: ::V1::Schemas::Fleets::Events::FleetEventSignup
                  }
                },
                required: %w[teams unassignedSignups]
              }
            ]
          })
        end
      end
    end
  end
end
