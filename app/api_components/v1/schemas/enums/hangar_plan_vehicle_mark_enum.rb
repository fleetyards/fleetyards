# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanVehicleMarkEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlanVehicleMark::MARKS,
          "x-enumNames": ::HangarPlanVehicleMark::MARKS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
