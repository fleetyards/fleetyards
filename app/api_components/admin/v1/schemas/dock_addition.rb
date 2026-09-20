# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class DockAddition
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            dockId: {type: :string, format: :uuid},
            modelId: {type: :string, format: :uuid},
            # Enough to render the row without a second request per ship.
            modelName: {type: :string},
            modelSlug: {type: :string},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id dockId modelId modelName modelSlug createdAt updatedAt]
        })
      end
    end
  end
end
