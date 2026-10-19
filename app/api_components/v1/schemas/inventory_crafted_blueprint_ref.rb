# frozen_string_literal: true

module V1
  module Schemas
    # The recipe a crafted part was made from, named well enough to link to it.
    class InventoryCraftedBlueprintRef
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string}
        },
        required: %w[id name slug]
      })
    end
  end
end
