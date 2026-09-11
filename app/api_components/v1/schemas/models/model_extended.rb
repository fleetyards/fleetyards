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
              items: ::Shared::V1::Schemas::DockCount
            },
            links: Shared::V1::Schemas::ModelExtendedLinks,
            # The ships this one can be carried by. Always present; empty when
            # nothing takes it and equally empty when the model has no
            # dimensions of its own, since an unmeasured hull is not compared.
            carriedBy: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  slug: {type: :string},
                  name: {type: :string},
                  dockType: {type: :string},
                  storeImage: ::Shared::V1::Schemas::MediaFile
                },
                additionalProperties: false,
                required: %w[slug name dockType]
              }
            }
          },
          required: %w[dockCounts links carriedBy]
        })
      end
    end
  end
end
