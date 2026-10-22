# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class SyncRsiBuybacksInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            items: {
              type: :array,
              items: ::V1::Schemas::Inputs::RsiBuybackItemInput
            },
            buybackTokens: {
              type: :integer,
              minimum: 0,
              description: "How many buy-backs RSI lets the user pay with store credit, as its buy-back page says"
            }
          },
          additionalProperties: false,
          required: %w[items]
        })
      end
    end
  end
end
