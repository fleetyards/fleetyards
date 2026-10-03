# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class ImportLoaderEnum
          include OpenapiRuby::Components::Base

          VALUES = ::Imports::Loaders::KEYS

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
