# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventSignupVehicleModel
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              classification: {type: :string},
              foci: {type: :array, items: ::Shared::V1::Schemas::Enums::ModelFocusEnum},
              size: {type: :string},
              crew: {type: [:integer, :null]},
              cargo: {type: :integer},
              image: ::Shared::V1::Schemas::MediaFile,
              positionCount: {type: :integer}
            }
          })
        end
      end
    end
  end
end
