# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelHardpointSubCategoryEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::ModelHardpoint.sub_categories.keys,
            "x-enumNames": ::ModelHardpoint.sub_categories.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
