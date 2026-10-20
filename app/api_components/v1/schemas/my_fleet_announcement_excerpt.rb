# frozen_string_literal: true

module V1
  module Schemas
    class MyFleetAnnouncementExcerpt
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          excerpt: {type: :string},
          createdAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id excerpt createdAt]
      })
    end
  end
end
