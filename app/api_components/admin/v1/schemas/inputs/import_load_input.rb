# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ImportLoadInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              loader: ::Admin::V1::Schemas::Enums::ImportLoaderEnum,
              # Which sc_data environment to load; the default one when left
              # out. Only the sc_data load reads it.
              environment: {type: :string, enum: ::Imports::Loaders.environments}
            },
            additionalProperties: false,
            required: %w[loader]
          })
        end
      end
    end
  end
end
