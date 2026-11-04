# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetchartLayoutInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            colored: {type: :boolean},
            background: ::V1::Schemas::Enums::FleetchartBackgroundEnum,
            placements: {type: :array, items: ::V1::Schemas::Hangar::FleetchartLayouts::FleetchartPlacement},
            cataloguePlacements: {type: :array, items: ::V1::Schemas::Hangar::FleetchartLayouts::FleetchartCataloguePlacement}
          },
          additionalProperties: false
        })
      end
    end
  end
end
