# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarSyncSubmitResult
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            status: {type: :string, enum: %w[pending]}
          },
          additionalProperties: false,
          required: %w[id status]
        })
      end
    end
  end
end
