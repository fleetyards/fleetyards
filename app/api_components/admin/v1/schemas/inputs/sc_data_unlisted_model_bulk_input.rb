# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ScDataUnlistedModelBulkInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              # The entries the decision applies to. Everything else about the
              # decision is in the path, so the three bulk actions share this.
              ids: {type: :array, items: {type: :string, format: :uuid}}
            },
            additionalProperties: false,
            required: %w[ids]
          })
        end
      end
    end
  end
end
