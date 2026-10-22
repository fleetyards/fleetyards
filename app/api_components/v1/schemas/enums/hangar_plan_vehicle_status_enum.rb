# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanVehicleStatusEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlans::Comparison::VEHICLE_STATUSES,
          "x-enumNames": ::HangarPlans::Comparison::VEHICLE_STATUSES.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
