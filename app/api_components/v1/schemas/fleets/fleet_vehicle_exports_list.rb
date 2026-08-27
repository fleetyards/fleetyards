# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetVehicleExportsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/FleetVehicleExport"}
        })
      end
    end
  end
end
