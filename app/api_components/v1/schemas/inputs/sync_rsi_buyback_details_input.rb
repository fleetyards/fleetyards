# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class SyncRsiBuybackDetailsInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            items: {
              type: :array,
              maxItems: 100,
              items: ::V1::Schemas::Inputs::RsiBuybackDetailInput
            }
          },
          additionalProperties: false,
          required: %w[items]
        })
      end
    end
  end
end
