# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # The other fleet in an alliance: enough to name it and link to it, and
      # nothing about what it holds. What an ally may *read* of a fleet is a
      # separate question, answered by `Public::FleetPolicy`.
      class AlliedFleet
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            logo: ::Shared::V1::Schemas::MediaFile
          },
          additionalProperties: false,
          required: %w[id name slug]
        })
      end
    end
  end
end
