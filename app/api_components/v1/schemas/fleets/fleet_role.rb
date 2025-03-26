# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetRole
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            resourceAccess: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          required: %w[id name slug resourceAccess]
        })
      end
    end
  end
end
