# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetVehicleExportsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Fleets::FleetVehicleExport
        })
      end
    end
  end
end
