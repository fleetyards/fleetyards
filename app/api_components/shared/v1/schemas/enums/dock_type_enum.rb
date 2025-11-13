# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class DockTypeEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::Dock.dock_types.keys
          })
        end
      end
    end
  end
end
