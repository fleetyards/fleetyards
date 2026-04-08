# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ImageUpdateBulkInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              ids: {type: :array, items: {type: :string, format: :uuid}},
              enabled: {type: :boolean},
              global: {type: :boolean},
              background: {type: :boolean},
              caption: {type: :string}
            },
            additionalProperties: false,
            required: %w[ids]
          })
        end
      end
    end
  end
end
