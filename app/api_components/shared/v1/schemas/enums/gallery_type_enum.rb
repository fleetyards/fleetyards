# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class GalleryTypeEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: %w[Model Station Album]
          })
        end
      end
    end
  end
end
