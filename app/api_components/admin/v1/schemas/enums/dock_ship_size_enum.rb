# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        # Only the admin Dock carries these raw values; the public payload
        # humanizes the size and cannot put an enum on the type.
        class DockShipSizeEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Dock.ship_sizes.keys,
            "x-enumNames": ::Dock.ship_sizes.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
