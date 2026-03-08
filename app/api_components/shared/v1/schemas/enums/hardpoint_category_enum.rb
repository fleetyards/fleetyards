# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class HardpointCategoryEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::Hardpoint.categories.keys,
            "x-enumNames": ::Hardpoint.categories.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
