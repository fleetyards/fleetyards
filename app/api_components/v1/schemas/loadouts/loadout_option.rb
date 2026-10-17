# frozen_string_literal: true

module V1
  module Schemas
    module Loadouts
      # A component that fits a slot, with the slots it brings: a swapped mount
      # carries its own gun ports, empty.
      class LoadoutOption
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            component: ::V1::Schemas::Loadouts::LoadoutComponentRef,
            slots: {type: :array, items: ::V1::Schemas::Loadouts::LoadoutSlot}
          },
          additionalProperties: false,
          required: %w[component slots]
        })
      end
    end
  end
end
