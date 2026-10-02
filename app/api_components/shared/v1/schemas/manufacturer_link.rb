# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A manufacturer, named, for a link or a label.
      class ManufacturerLink
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[name slug]
        })
      end
    end
  end
end
