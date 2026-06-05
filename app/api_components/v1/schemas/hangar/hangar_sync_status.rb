# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarSyncStatus
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            active: {type: :boolean},
            status: {type: [:string, :null], enum: %w[created started finished failed]},
            result: {anyOf: [{"$ref": "#/components/schemas/HangarSyncResult"}, {type: :null}]}
          },
          additionalProperties: false,
          required: %w[active]
        })
      end
    end
  end
end
