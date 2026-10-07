# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class BuybackDetailsSyncResult
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            updated: {type: :integer}
          },
          additionalProperties: false,
          required: %w[updated]
        })
      end
    end
  end
end
