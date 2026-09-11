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
            # The ships this one can be carried by. Absent rather than empty when
            # the model has no dimensions of its own -- there is a difference
            # between "nothing takes it" and "nobody measured it".
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
