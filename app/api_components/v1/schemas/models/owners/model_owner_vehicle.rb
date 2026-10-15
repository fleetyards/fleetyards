# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Owners
        class ModelOwnerVehicle
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              serial: {type: :string},
              flagship: {type: :boolean},
              image: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false,
            required: %w[id flagship]
          })
        end
      end
    end
  end
end
