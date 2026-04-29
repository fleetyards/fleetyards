# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarSyncStatus
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            active: {type: :boolean},
            status: {type: :string, nullable: true, enum: %w[created started finished failed]},
            result: {"$ref": "#/components/schemas/HangarSyncResult", nullable: true}
          },
          additionalProperties: false,
          required: %w[active]
        })
      end
    end
  end
end
