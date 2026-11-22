# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        class FleetSquadronCapabilities
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              manageMembers: {type: :boolean},
              manageRanks: {type: :boolean},
              manageRoleFilter: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[manageMembers manageRanks manageRoleFilter]
          })
        end
      end
    end
  end
end
