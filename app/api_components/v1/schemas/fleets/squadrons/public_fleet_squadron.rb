# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        # Narrower than `FleetSquadron` on purpose: an outside reader gets the
        # name, the colour and the size, not the description and not the people.
        class PublicFleetSquadron
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              color: {type: [:string, :null]},
              memberCount: {type: :integer},
              icon: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false,
            required: %w[id name slug memberCount]
          })
        end
      end
    end
  end
end
