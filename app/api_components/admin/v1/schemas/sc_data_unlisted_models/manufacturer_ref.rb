# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module ScDataUnlistedModels
        # Enough to name the company the identifier prefix resolved to. The full
        # manufacturer payload carries logos and counts a row in this list has
        # no use for.
        class ManufacturerRef
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: [:string, :null]},
              code: {type: [:string, :null]},
              slug: {type: [:string, :null]}
            },
            additionalProperties: false,
            required: %w[id]
          })
        end
      end
    end
  end
end
