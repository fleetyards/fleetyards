# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # What a storage container holds: ore from a mining pod, or salvage.
        class StorageContainerKindEnum
          include OpenapiRuby::Components::Base

          VALUES = ::ModelBuild::STORAGE_KINDS

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
