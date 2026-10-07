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
            }
          },
          additionalProperties: false,
          required: %w[items]
        })
      end
    end
  end
end
