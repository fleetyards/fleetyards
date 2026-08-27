# frozen_string_literal: true

module V1
  module Schemas
    # The catalogue record a ledger entry points at.
    class InventoryItemRef
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          type: ::V1::Schemas::Enums::InventoryItemTypeEnum,
          name: {type: :string},
          slug: {type: :string},
          available: {type: :boolean}
        }
      })
    end
  end
end
