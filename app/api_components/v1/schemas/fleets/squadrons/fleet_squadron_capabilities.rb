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
              update: {type: :boolean},
              manageMembers: {type: :boolean},
              manageRanks: {type: :boolean},
              manageRoleFilter: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[update manageMembers manageRanks manageRoleFilter]
          })
        end
      end
    end
  end
end
