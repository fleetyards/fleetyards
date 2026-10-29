# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanVehicleMarkUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            mark: ::V1::Schemas::Enums::HangarPlanVehicleMarkEnum
          },
          required: %w[mark],
          additionalProperties: false
        })
      end
    end
  end
end
