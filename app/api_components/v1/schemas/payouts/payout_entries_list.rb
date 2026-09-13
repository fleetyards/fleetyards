# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      class PayoutEntriesList
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            items: {type: :array, items: PayoutEntry},
            meta: ::Shared::V1::Schemas::Meta
          },
          required: %w[items],
          additionalProperties: false
        })
      end
    end
  end
end
