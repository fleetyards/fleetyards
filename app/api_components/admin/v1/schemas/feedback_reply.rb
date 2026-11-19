# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class FeedbackReply
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            body: {type: :string},
            fromAdmin: {type: :boolean},
            adminName: {type: [:string, :null]},
            createdAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id body fromAdmin createdAt]
        })
      end
    end
  end
end
