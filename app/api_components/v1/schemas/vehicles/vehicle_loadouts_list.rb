# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadoutsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Vehicles::VehicleLoadout
        })
      end
    end
  end
end
