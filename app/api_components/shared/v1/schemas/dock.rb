# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Dock
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            group: {type: :string},
            size: ::Shared::V1::Schemas::Enums::DockShipSizeEnum,
            sizeLabel: {type: :string},
            type: ::Shared::V1::Schemas::Enums::DockTypeEnum,
            typeLabel: {type: :string}
          },
          additionalProperties: false,
          required: %w[name size sizeLabel type typeLabel]
        })
      end
    end
  end
end
