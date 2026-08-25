# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetResourceAccessGroup
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            key: {type: :string},
            privileges: {type: :array, items: {"$ref": "#/components/schemas/FleetRoleResourceAccessEnum"}},
            managePrivilege: {"$ref": "#/components/schemas/FleetRoleResourceAccessEnum"}
          },
          additionalProperties: false,
          required: %w[key privileges]
        })
      end
    end
  end
end
