# frozen_string_literal: true

module V1
  module Schemas
    module Feedbacks
      class Feedback
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            message: {type: :string},
            featureName: {type: [:string, :null]},
            pagePath: {type: [:string, :null]},
            state: ::V1::Schemas::Enums::FeedbackStateEnum,
            repliesCount: {type: :integer},
            replies: {type: :array, items: ::V1::Schemas::Feedbacks::FeedbackReply},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id message state repliesCount createdAt updatedAt]
        })
      end
    end
  end
end
