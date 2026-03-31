# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ComponentItemClassEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::Component.item_classes.keys,
            "x-enumNames": ::Component.item_classes.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
