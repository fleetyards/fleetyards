# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class DockTypeEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::Dock.dock_types.keys
        })
      end
    end
  end
end
