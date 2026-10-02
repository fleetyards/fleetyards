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
              permanent: {type: :boolean},
              # The rank new squadron members start on; exactly one per fleet.
              defaultRank: {type: :boolean},
              # What the slot may do, so no client keeps its own copy of it.
              singleHolder: {type: :boolean},
              managesMembers: {type: :boolean},
              managesRanks: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[id key name position permanent defaultRank singleHolder managesMembers managesRanks]
          })
        end
      end
    end
  end
end
