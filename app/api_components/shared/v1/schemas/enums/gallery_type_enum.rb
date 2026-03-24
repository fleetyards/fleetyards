# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class GalleryTypeEnum
          include Rswag::SchemaComponents::Component

          TYPES = %w[Model Album].freeze

          schema({
            type: :string,
            enum: TYPES,
            "x-enumNames": TYPES.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
