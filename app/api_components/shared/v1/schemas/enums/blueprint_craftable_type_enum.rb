# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # Which catalogue a recipe's output is in. Sourced from the model rather
        # than retyped, so it cannot drift from what the association allows.
        class BlueprintCraftableTypeEnum
          include OpenapiRuby::Components::Base

          VALUES = ::Blueprint::CRAFTABLE_TYPES

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
