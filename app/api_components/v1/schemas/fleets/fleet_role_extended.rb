# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetRoleExtended < FleetRole
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            rank: {type: :string},
            permanent: {type: :boolean},
            # The role new members get; exactly one per fleet.
            defaultRole: {type: :boolean},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[rank defaultRole createdAt updatedAt]
        })
      end
    end
  end
end
