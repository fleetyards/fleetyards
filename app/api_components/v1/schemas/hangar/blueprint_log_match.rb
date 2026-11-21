# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      # One name from the logs and every blueprint it can mean: none when the
      # catalogue has no such name, more than one where two recipes make
      # items sharing it.
      class BlueprintLogMatch
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            blueprints: {
              type: :array,
              items: ::V1::Schemas::Hangar::BlueprintLogMatchOption
            }
          },
          additionalProperties: false,
          required: %w[name blueprints]
        })
      end
    end
  end
end
