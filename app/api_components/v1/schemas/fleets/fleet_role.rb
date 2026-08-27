# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetRole
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            resourceAccess: {type: :array, items: ::V1::Schemas::Enums::FleetRoleResourceAccessEnum}
          },
          additionalProperties: false,
          required: %w[id name slug]
        })
      end
    end
  end
end
