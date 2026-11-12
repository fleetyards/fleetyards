# frozen_string_literal: true

module V1
  module Schemas
    # What the current build changed about the reader's own ships and the ones
    # on their wishlist. `totalCount` counts every such ship; `items` holds the
    # most changed of them. `ownedCount` and `ownedModelIds` cover the owned
    # ones alone, all of them, so a ship outside `items` can still be marked.
    class MyPatchChanges
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          environment: {type: :string},
          version: {type: :string},
          fromVersion: {type: :string},
          totalCount: {type: :integer},
          ownedCount: {type: :integer},
          ownedModelIds: {type: :array, items: {type: :string, format: :uuid}},
          items: {type: :array, items: ::V1::Schemas::MyPatchChange}
        },
        additionalProperties: false,
        required: %w[environment version totalCount ownedCount ownedModelIds items]
      })
    end
  end
end
