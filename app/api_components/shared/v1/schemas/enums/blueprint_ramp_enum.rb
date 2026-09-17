# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # How a slot moves a stat over material quality: "linear" scales it,
        # "linear_integer_additive" adds to it.
        class BlueprintRampEnum
          include OpenapiRuby::Components::Base

          VALUES = ::BlueprintCostModifier::RAMPS

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
