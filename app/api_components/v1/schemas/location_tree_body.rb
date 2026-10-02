# frozen_string_literal: true

module V1
  module Schemas
    class LocationTreeBody
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: [:string, :null]},
          slug: {type: :string},
          kind: ::Shared::V1::Schemas::Enums::LocationKindEnum,
          parentName: {type: [:string, :null]},
          shownOnStarmap: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[id slug kind parentName shownOnStarmap]
      })
    end
  end
end
