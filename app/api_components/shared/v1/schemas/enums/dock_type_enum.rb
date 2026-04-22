# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class DockTypeEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Dock.dock_types.keys,
            "x-enumNames": ::Dock.dock_types.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
