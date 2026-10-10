# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class RsiHangarUnreadPageInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            check: ::V1::Schemas::Enums::RsiPageCheckEnum,
            pageNumber: {type: :integer, minimum: 1},
            details: {
              type: :array,
              maxItems: 10,
              items: {type: :string, pattern: "^[^`\\r\\n]{1,200}$"}
            },
            markup: {
              type: :array,
              maxItems: 5,
              items: {type: :string, maxLength: 20_000}
            }
          },
          additionalProperties: false,
          required: %w[check]
        })
      end
    end
  end
end
