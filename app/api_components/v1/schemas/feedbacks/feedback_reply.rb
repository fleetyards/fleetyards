# frozen_string_literal: true

module V1
  module Schemas
    module Feedbacks
      class FeedbackReply
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            body: {type: :string},
            fromAdmin: {type: :boolean},
            createdAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id body fromAdmin createdAt]
        })
      end
    end
  end
end
