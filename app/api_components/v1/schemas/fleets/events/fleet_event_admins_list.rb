# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventAdminsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/FleetEventAdmin"}
          })
        end
      end
    end
  end
end
