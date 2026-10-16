# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # An item type a rack slot takes, as the game names it, with the
      # sub-types it narrows to -- `WeaponPersonal` / `Gadget` for a tractor
      # beam or multitool, `Cargo` for a smuggling stash.
      class WeaponRackSlotType
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            type: {type: :string},
            subTypes: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          required: %w[type subTypes]
        })
      end
    end
  end
end
