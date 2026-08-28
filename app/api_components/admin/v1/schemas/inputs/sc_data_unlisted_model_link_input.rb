# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ScDataUnlistedModelLinkInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              # Which ship in the catalogue this game-file entry already is. The
              # detected match is only a suggestion, so the admin names it.
              modelId: {type: :string, format: :uuid}
            },
            additionalProperties: false,
            required: %w[modelId]
          })
        end
      end
    end
  end
end
