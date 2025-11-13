# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Sorts
        class FleetVehicleSortEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: FleetVehicle::ALLOWED_SORTING_PARAMS
          })
        end
      end
    end
  end
end
