# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        # A squadron as it appears on somebody else's record -- a badge on the
        # roster. Enough to name it, colour it and link to it, and no more.
        class FleetSquadronRef
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              color: {type: [:string, :null]},
              # Carried because the member picker has to say why somebody
              # cannot be added, which means knowing which of the squadrons
              # they already hold is an ordinary one rather than a team.
              team: {type: :boolean},
              membershipCreatedAt: {type: [:string, :null], format: "date-time"},
              # Only on an event's squadrons: the editor warns about a squadron
              # its announcement cannot reach, even once the fleet's own
              # squadron list is no longer served.
              discordChannelId: {type: [:string, :null]},
              icon: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false,
            required: %w[id name slug team]
          })
        end
      end
    end
  end
end
