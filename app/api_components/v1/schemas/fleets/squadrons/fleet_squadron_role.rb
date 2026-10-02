# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        # A rank held within a squadron. `name` is the fleet's to choose;
        # `key` is the fixed slot, and the one to compare against.
        class FleetSquadronRole
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              key: ::V1::Schemas::Enums::FleetSquadronRoleKeyEnum,
              name: {type: :string},
              position: {type: :integer},
              # What the slot may do, so no client keeps its own copy of it.
              singleHolder: {type: :boolean},
              managesMembers: {type: :boolean},
              managesRanks: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[id key name position singleHolder managesMembers managesRanks]
          })
        end
      end
    end
  end
end
