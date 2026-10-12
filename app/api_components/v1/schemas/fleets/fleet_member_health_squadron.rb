# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMemberHealthSquadron
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            team: {type: :boolean},
            createdAt: {type: :string, format: "date-time"}
          },
          required: %w[id name slug team createdAt],
          additionalProperties: false
        })
      end
    end
  end
end
