# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Ore pods and salvage storage: what a ship holds that is not cargo space.
      class StorageContainer
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            componentName: {type: [:string, :null]},
            capacity: {type: :number},
            kind: ::Shared::V1::Schemas::Enums::StorageContainerKindEnum
          },
          additionalProperties: false,
          required: %w[capacity kind]
        })
      end
    end
  end
end
