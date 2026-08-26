# frozen_string_literal: true

module V1
  module Schemas
    module Models
      # The ship views a fleetchart draws with, and nothing else. Keyed by slug so
      # a caller matches them against a list it already holds.
      class FleetchartView
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slug: {type: :string},
            media: FleetchartViewMedia
          },
          required: %w[slug media]
        })
      end
    end
  end
end
