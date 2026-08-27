# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        # Only the admin Dock carries these raw values; the public payload
        # humanizes the size and cannot put an enum on the type.
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
