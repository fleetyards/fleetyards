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
            removed: {type: :integer}
          },
          additionalProperties: false,
          required: %w[total added removed]
        })
      end
    end
  end
end
