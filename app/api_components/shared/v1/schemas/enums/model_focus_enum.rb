# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelFocusEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Model::FOCI,
            "x-enumNames": ::Model::FOCI.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
