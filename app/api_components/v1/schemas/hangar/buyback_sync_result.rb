# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class BuybackSyncResult
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            total: {type: :integer},
            added: {type: :integer},
            removed: {type: :integer},
            detailsPending: {type: :array, items: {type: :string}},
            importId: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: %w[total added removed detailsPending importId]
        })
      end
    end
  end
end
