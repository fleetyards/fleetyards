# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class RsiRequestLog
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: "uuid"},
            url: {type: :string},
            resolved: {type: :boolean},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id url resolved createdAt updatedAt]
        })
      end
    end
  end
end
