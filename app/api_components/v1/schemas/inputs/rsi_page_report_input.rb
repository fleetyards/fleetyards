# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class RsiPageReportInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            page: {"$ref": "#/components/schemas/RsiPageKindEnum"},
            check: {"$ref": "#/components/schemas/RsiPageCheckEnum"},
            pageNumber: {type: :integer, minimum: 1},
            extensionVersion: {type: :string, maxLength: 32}
          },
          additionalProperties: false,
          required: %w[page check]
        })
      end
    end
  end
end
