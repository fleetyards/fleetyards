# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class DockShipSizeEnum
          include Rswag::SchemaComponents::Component

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
