# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A contract that hands a blueprint out, and the star systems it is
      # offered in.
      class BlueprintSourceMission
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: [:string, :null]},
            slug: {type: :string},
            systems: {type: :array, items: ::Shared::V1::Schemas::LocationLink}
          },
          additionalProperties: false,
          required: %w[id slug systems]
        })
      end
    end
  end
end
