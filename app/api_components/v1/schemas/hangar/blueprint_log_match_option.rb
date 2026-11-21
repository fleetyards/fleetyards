# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class BlueprintLogMatchOption
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slug: {type: :string},
            name: {type: :string},
            owned: {type: :boolean},
            wanted: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[slug name owned wanted]
        })
      end
    end
  end
end
