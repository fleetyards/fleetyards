# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class PayoutEntryDeclineInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            reason: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
