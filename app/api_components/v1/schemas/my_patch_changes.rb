# frozen_string_literal: true

module V1
  module Schemas
    # What the current build changed about the reader's own ships and the ones
    # on their wishlist. `totalCount` counts every such ship; `items` holds the
    # most changed of them.
    class MyPatchChanges
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          environment: {type: :string},
          version: {type: :string},
          fromVersion: {type: :string},
          totalCount: {type: :integer},
          items: {type: :array, items: ::V1::Schemas::MyPatchChange}
        },
        additionalProperties: false,
        required: %w[environment version totalCount items]
      })
    end
  end
end
