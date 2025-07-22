# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class HardpointCategoryEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Hardpoint.categories.keys
          })
        end
      end
    end
  end
end
