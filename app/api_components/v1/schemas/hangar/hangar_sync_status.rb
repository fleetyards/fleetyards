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
            status: ::V1::Schemas::Enums::HangarSyncStatusEnum,
            result: ::V1::Schemas::Hangar::HangarSyncResult
          },
          additionalProperties: false,
          required: %w[active]
        })
      end
    end
  end
end
