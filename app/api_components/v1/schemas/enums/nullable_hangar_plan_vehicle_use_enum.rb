# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class NullableHangarPlanVehicleUseEnum
        include OpenapiRuby::Components::Base

        schema({
          type: [:string, :null],
          enum: ::HangarPlans::Resources::USES + [nil],
          "x-enumNames": ::HangarPlans::Resources::USES.map { |v| transform_enum_key(v) } + ["NULL"]
        })
      end
    end
  end
end
