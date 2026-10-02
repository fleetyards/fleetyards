# frozen_string_literal: true

module V1
  module Schemas
    class LocationContents
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          groups: {type: :array, items: ::V1::Schemas::LocationContentsGroup}
        },
        additionalProperties: false,
        required: %w[groups]
      })
    end
  end
end
