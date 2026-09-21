# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        class FleetSquadron
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              description: {type: [:string, :null]},
              color: {type: [:string, :null]},
              memberCount: {type: :integer},
              logo: ::Shared::V1::Schemas::MediaFile,
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name slug memberCount createdAt updatedAt]
          })
        end
      end
    end
  end
end
