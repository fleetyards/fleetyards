# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetResourceAccessGroupsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/FleetResourceAccessGroup"}
        })
      end
    end
  end
end
