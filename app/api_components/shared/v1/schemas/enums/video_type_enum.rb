# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class VideoTypeEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Video.video_types.keys,
            "x-enumNames": ::Video.video_types.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
