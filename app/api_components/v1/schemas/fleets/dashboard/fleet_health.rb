# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Dashboard
        # `null` where the question does not apply to this fleet or reader:
        # unverified members without an RSI org to verify against, empty roles
        # for a reader who may not see roles.
        class FleetHealth
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              inactiveMembers: ::V1::Schemas::Fleets::Dashboard::FleetHealthMembers,
              unverifiedMembers: {anyOf: [::V1::Schemas::Fleets::Dashboard::FleetHealthMembers, {type: :null}]},
              emptyRoles: {
                type: [:array, :null],
                items: ::V1::Schemas::Fleets::Dashboard::FleetHealthRole
              }
            },
            required: %w[inactiveMembers]
          })
        end
      end
    end
  end
end
