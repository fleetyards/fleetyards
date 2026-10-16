# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A place on a rack: the item types and sizes it takes, and the tags an
      # item must carry when the slot is kept for one kind, such as multitools.
      class WeaponRackSlot
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            minSize: {type: :integer},
            maxSize: {type: :integer},
            types: {type: :array, items: ::Shared::V1::Schemas::WeaponRackSlotType},
            requiredTags: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          required: %w[minSize maxSize types]
        })
      end
    end
  end
end
