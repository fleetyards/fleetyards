# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelHardpointSizeEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::ModelHardpoint.sizes.keys,
            "x-enumNames": ::ModelHardpoint.sizes.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
