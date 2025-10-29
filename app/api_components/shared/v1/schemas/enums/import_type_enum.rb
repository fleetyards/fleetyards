# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ImportTypeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: %w[
              Imports::ModelImport Imports::ModelsImport Imports::ScData::AllImport
              Imports::ScData::ModelsImport Imports::ScData::ModelImport Imports::HangarSync
              Imports::HangarImport
            ]
          })
        end
      end
    end
  end
end
