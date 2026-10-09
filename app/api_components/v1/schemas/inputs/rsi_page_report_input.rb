# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class RsiPageReportInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            page: ::V1::Schemas::Enums::RsiPageKindEnum,
            check: ::V1::Schemas::Enums::RsiPageCheckEnum,
            pageNumber: {type: :integer, minimum: 1},
            extensionVersion: {type: :string, pattern: "^[0-9A-Za-z.+-]{1,32}$"},
            details: {
              type: :array,
              maxItems: 10,
              items: {type: :string, pattern: "^[^`\\r\\n]{1,200}$"}
            }
          },
          additionalProperties: false,
          required: %w[page check]
        })
      end
    end
  end
end
