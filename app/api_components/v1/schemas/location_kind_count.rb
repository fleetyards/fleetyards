# frozen_string_literal: true

module V1
  module Schemas
    class LocationKindCount
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          kind: ::Shared::V1::Schemas::Enums::LocationKindEnum,
          count: {type: :integer}
        },
        additionalProperties: false,
        required: %w[kind count]
      })
    end
  end
end
