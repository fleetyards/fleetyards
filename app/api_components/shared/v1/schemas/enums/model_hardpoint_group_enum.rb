# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelHardpointGroupEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::ModelHardpoint.groups.keys,
            "x-enumNames": ::ModelHardpoint.groups.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
