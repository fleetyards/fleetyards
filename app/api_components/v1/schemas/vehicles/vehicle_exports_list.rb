# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleExportsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/VehicleExport"}
        })
      end
    end
  end
end
