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
            placements: {type: :array, items: ::V1::Schemas::Hangar::FleetchartLayouts::FleetchartPlacement}
          },
          additionalProperties: false
        })
      end
    end
  end
end
