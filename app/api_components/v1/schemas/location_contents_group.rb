# frozen_string_literal: true

module V1
  module Schemas
    class LocationContentsGroup
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          kind: ::Shared::V1::Schemas::Enums::LocationKindEnum,
          count: {type: :integer},
          entries: {type: :array, items: ::V1::Schemas::LocationContentsEntry}
        },
        additionalProperties: false,
        required: %w[kind count entries]
      })
    end
  end
end
