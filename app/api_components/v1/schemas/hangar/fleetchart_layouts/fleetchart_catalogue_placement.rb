# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module FleetchartLayouts
        class FleetchartCataloguePlacement
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, minLength: 1, maxLength: 64},
              modelId: {type: :string, format: :uuid},
              x: {type: :number},
              y: {type: :number},
              facing: ::V1::Schemas::Enums::FleetchartFacingEnum,
              viewpoint: ::V1::Schemas::Enums::FleetchartViewpointEnum,
              state: ::V1::Schemas::Enums::FleetchartShipStateEnum,
              order: {type: [:number, :null]},
              groupId: {type: [:string, :null]},
              heading: {type: [:string, :null]}
            },
            required: %w[id modelId x y],
            additionalProperties: false
          })
        end
      end
    end
  end
end
