# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The inventory an entry belongs to, by name and slug.
      class InventoryRef
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            slug: {type: :string}
          }
        })
      end
    end
  end
end
