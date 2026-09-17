# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # Also the unit: a resource is measured in SCU, an item in whole pieces.
        class BlueprintCostTypeEnum
          include OpenapiRuby::Components::Base

          VALUES = ::BlueprintCostOption::TYPES

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
