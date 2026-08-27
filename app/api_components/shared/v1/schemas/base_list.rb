# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Published without any $ref pointing at it on purpose: subclasses
      # inherit the schema rather than referencing it, and the frontend
      # imports the generated type for its pagination components.
      class BaseList
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            meta: ::Shared::V1::Schemas::Meta
          },
          additionalProperties: false,
          required: %w[meta]
        })
      end
    end
  end
end
