# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class FeedbackReplyInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              body: {type: :string, minLength: 1, maxLength: ::FeedbackReply::BODY_MAX_LENGTH}
            },
            additionalProperties: false,
            required: %w[body]
          })
        end
      end
    end
  end
end
