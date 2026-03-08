# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelHardpointTypeEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::ModelHardpoint.hardpoint_types.keys,
            "x-enumNames": ::ModelHardpoint.hardpoint_types.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
