# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMemberHealth
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            inactiveDays: {type: :integer},
            inactiveMembers: ::V1::Schemas::Fleets::FleetMemberHealthSection,
            fleetRsiVerified: {type: :boolean},
            unverifiedMembers: {
              anyOf: [::V1::Schemas::Fleets::FleetMemberHealthSection, {type: :null}],
              description: "Null when the fleet has no RSI SID to verify against"
            },
            emptyRoles: {
              anyOf: [{type: :array, items: ::V1::Schemas::Fleets::FleetRole}, {type: :null}],
              description: "Null when the reader cannot read roles"
            }
          },
          required: %w[inactiveDays inactiveMembers fleetRsiVerified unverifiedMembers emptyRoles],
          additionalProperties: false
        })
      end
    end
  end
end
