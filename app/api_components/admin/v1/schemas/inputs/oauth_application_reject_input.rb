# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class OauthApplicationRejectInput
          include OpenapiRuby::Components::Base

          # The reason is what the owner is shown, so it is required here rather
          # than optional with a validation waiting behind it.
          schema({
            type: :object,
            properties: {
              rejectionReason: {type: :string}
            },
            additionalProperties: false,
            required: %w[rejectionReason]
          })
        end
      end
    end
  end
end
