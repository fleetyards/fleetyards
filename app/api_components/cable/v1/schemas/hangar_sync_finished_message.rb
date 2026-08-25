# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      class HangarSyncFinishedMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            status: {type: :string, enum: %w[finished]},
            result: {"$ref": "#/components/schemas/HangarSyncResult"}
          },
          additionalProperties: false,
          required: %w[status result]
        })
      end
    end
  end
end
