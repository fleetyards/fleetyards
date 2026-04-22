# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class RsiHangarItemKindEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::HangarSync::ITEM_TYPES,
            "x-enumNames": ::HangarSync::ITEM_TYPES.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
