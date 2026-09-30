# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ComponentTurretControlEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Component::TURRET_CONTROLS,
            "x-enumNames": ::Component::TURRET_CONTROLS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
