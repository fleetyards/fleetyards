# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module FleetchartLayouts
        class FleetchartPlacement
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              vehicleId: {type: :string, format: :uuid},
              x: {type: :number},
              y: {type: :number},
              facing: ::V1::Schemas::Enums::FleetchartFacingEnum,
              viewpoint: ::V1::Schemas::Enums::FleetchartViewpointEnum,
              state: ::V1::Schemas::Enums::FleetchartShipStateEnum,
              order: {type: [:number, :null]},
              groupId: {type: [:string, :null]},
              heading: {type: [:string, :null]},
              removed: {type: [:boolean, :null], description: "Kept out of the chart, where a ship without a placement would show as not placed yet"}
            },
            required: %w[vehicleId x y],
            additionalProperties: false
          })
        end
      end
    end
  end
end
