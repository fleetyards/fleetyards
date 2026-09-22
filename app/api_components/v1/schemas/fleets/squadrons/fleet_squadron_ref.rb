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
              logo: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false,
            required: %w[id name slug]
          })
        end
      end
    end
  end
end
