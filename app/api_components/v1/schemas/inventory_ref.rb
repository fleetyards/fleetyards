# frozen_string_literal: true

module V1
  module Schemas
    # The inventory an entry belongs to, by name and slug.
    class InventoryRef
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},

          # Present where the inventory belongs to a ship rather than standing
          # on its own, so a caller can say where the stock actually sits.
          vehicleName: {type: :string}
        }
      })
    end
  end
end
