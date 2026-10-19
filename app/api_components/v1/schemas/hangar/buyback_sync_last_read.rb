# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class BuybackSyncLastRead
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            finishedAt: {type: [:string, :null], format: "date-time"},
            pages: {type: [:integer, :null]},
            total: {type: :integer}
          },
          additionalProperties: false,
          required: %w[total]
        })
      end
    end
  end
end
