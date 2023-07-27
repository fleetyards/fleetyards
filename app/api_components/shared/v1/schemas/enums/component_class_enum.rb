# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ComponentClassEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Component.component_classes
          })
        end
      end
    end
  end
end
