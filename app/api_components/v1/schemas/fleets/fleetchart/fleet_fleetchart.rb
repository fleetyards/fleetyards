# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Fleetchart
        class FleetFleetchart
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              models: {type: :array, items: ::V1::Schemas::Models::FleetchartModel},
              modulePackages: {type: :array, items: ::V1::Schemas::Models::ModulePackages::ModelModulePackage},
              items: {type: :array, items: FleetFleetchartShip}
            },
            required: %w[models modulePackages items]
          })
        end
      end
    end
  end
end
