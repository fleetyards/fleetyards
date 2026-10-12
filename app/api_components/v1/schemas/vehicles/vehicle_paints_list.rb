# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehiclePaintsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Vehicles::VehiclePaint
        })
      end
    end
  end
end
