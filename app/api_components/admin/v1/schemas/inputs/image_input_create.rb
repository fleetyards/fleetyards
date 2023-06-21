# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ImageInputCreate < ImageInput
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              file: {type: :string}
            }
          })
        end
      end
    end
  end
end
