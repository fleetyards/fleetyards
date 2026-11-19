# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Feedback
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            message: {type: :string},
            featureName: {type: [:string, :null]},
            pagePath: {type: [:string, :null]},
            state: ::Admin::V1::Schemas::Enums::FeedbackStateEnum,
            userId: {type: :string, format: :uuid},
            username: {type: [:string, :null]},
            resolvedAt: {type: [:string, :null], format: "date-time"},
            resolvedByName: {type: [:string, :null]},
            repliesCount: {type: :integer},
            replies: {type: :array, items: ::Admin::V1::Schemas::FeedbackReply},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id message state userId repliesCount createdAt updatedAt]
        })
      end
    end
  end
end
