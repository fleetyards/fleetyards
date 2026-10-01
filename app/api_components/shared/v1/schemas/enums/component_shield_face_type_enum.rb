# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ComponentShieldFaceTypeEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Component::SHIELD_FACE_TYPES,
            "x-enumNames": ::Component::SHIELD_FACE_TYPES.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
