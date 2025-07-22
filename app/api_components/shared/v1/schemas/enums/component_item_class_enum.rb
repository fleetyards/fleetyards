# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ComponentItemClassEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Component.item_classes.keys
          })
        end
      end
    end
  end
end
