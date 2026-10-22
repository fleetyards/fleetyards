# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanWishlistResult
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              added: {type: :integer},
              skipped: {type: :integer}
            },
            additionalProperties: false,
            required: %w[added skipped]
          })
        end
      end
    end
  end
end
