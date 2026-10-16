# frozen_string_literal: true

module V1
  module Schemas
    class VersionAnnouncement
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          title: {type: :string},
          link: {type: :string},
          publishedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %i[title link publishedAt]
      })
    end
  end
end
