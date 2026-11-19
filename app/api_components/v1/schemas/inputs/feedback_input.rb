# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FeedbackInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            message: {type: :string, minLength: 1, maxLength: ::Feedback::MESSAGE_MAX_LENGTH},
            featureName: {type: [:string, :null]},
            pagePath: {type: [:string, :null], maxLength: 2048}
          },
          additionalProperties: false,
          required: %w[message]
        })
      end
    end
  end
end
