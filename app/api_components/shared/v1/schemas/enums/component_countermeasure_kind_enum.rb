# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ComponentCountermeasureKindEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Component::COUNTERMEASURE_KINDS,
            "x-enumNames": ::Component::COUNTERMEASURE_KINDS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
