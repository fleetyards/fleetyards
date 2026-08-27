# frozen_string_literal: true

module V1
  module Schemas
    module Models
      class ModelExtended < Model
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            dockCounts: {
              type: :array,
              items: {"$ref": "#/components/schemas/DockCount"}
            },
            links: Shared::V1::Schemas::ModelExtendedLinks
          },
          required: %w[dockCounts links]
        })
      end
    end
  end
end
