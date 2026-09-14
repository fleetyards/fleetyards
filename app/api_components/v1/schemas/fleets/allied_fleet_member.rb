# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # A member as an allied fleet sees them. Deliberately not
      # `::V1::Schemas::Fleets::FleetMember` and deliberately not derived from
      # it: that one carries contact handles, coordinates, a current system and
      # activity timestamps, and the point of this schema is that none of them
      # can arrive here by being added there.
      #
      # `username` and `avatar` are absent for a member who has set
      # `hide_owner`, which `hidden` announces so a client can render the place
      # without inventing a name for it.
      class AlliedFleetMember
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            hidden: {type: :boolean},
            username: {type: :string},
            avatar: ::Shared::V1::Schemas::MediaFile,
            role: {type: [:string, :null]}
          },
          additionalProperties: false,
          required: %w[id hidden role]
        })
      end
    end
  end
end
