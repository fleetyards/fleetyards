# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class VersionItemTypeEnum
          include OpenapiRuby::Components::Base

          TYPES = ::VersionedItem::TYPES

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
