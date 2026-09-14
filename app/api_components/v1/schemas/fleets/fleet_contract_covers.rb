# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # A fleet's own cover art, one per contract kind. Absent where the fleet
      # has uploaded none — the client falls back to the built-in art.
      class FleetContractCovers
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: ::FleetContract::KINDS.keys.to_h { |kind|
            [kind.to_s, ::Shared::V1::Schemas::MediaFile]
          },
          additionalProperties: false
        })
      end
    end
  end
end
