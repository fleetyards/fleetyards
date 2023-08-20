# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class DockShipSizeEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::Dock.ship_sizes.keys
        })
      end
    end
  end
end
