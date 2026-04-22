# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ImportTypeEnum
          include OpenapiRuby::Components::Base

          TYPES = %w[
            Imports::ModelImport Imports::ModelsImport Imports::ScData::AllImport
            Imports::ScData::ModelsImport Imports::ScData::ModelImport Imports::HangarSync
            Imports::HangarImport
          ].freeze

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
