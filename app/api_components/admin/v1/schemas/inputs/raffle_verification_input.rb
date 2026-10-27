# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class RaffleVerificationInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              verificationCode: {type: :string}
            },
            additionalProperties: false,
            required: %w[verificationCode]
          })
        end
      end
    end
  end
end
