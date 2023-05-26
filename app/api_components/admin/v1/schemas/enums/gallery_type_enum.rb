# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class GalleryTypeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: %w[Model Station Album]
          })
        end
      end
    end
  end
end
