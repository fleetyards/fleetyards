# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class SupporterContributionUpdateBulkInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              ids: {type: :array, items: {type: :string, format: :uuid}},
              anonymous: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[ids anonymous]
          })
        end
      end
    end
  end
end
