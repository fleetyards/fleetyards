# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        class ModelExtended < Model
          include OpenapiRuby::Components::Base

          schema({
            properties: {
              baseModelId: {type: :string, format: :uuid},
              dockCounts: {
                type: :array,
                items: ::Shared::V1::Schemas::DockCount
              },
              links: ::Shared::V1::Schemas::ModelExtendedLinks,
              moduleSlots: {
                type: :array,
                items: {type: :string},
                description: "The module hardpoints the game files give the hull, by sc_name"
              },
              mediaProcessing: {
                type: :array,
                items: {type: :string},
                description: "Views whose upload is still being cropped in the background. Their media still names the uncropped file, which the crop replaces."
              }
            },
            required: %w[dockCounts links mediaProcessing moduleSlots]
          })
        end
      end
    end
  end
end
