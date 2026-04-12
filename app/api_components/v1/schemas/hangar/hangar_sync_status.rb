# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarSyncStatus
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            active: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[active]
        })
      end
    end
  end
end
