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
            createdAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id message createdAt]
        })
      end
    end
  end
end
