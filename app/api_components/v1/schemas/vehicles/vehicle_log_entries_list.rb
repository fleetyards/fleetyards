# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLogEntriesList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Vehicles::VehicleLogEntry
        })
      end
    end
  end
end
