# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class PayoutLedgerCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            notes: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
