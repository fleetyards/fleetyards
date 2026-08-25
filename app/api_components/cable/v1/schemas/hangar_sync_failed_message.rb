# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      class HangarSyncFailedMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            status: {type: :string, enum: %w[failed]},
            error: {type: :string}
          },
          additionalProperties: false,
          required: %w[status error]
        })
      end
    end
  end
end
