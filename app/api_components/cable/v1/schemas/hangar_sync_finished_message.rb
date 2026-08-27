# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      class HangarSyncFinishedMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            status: Cable::V1::Schemas::Enums::HangarSyncFinishedStatusEnum,
            result: ::V1::Schemas::Hangar::HangarSyncResult
          },
          additionalProperties: false,
          required: %w[status result]
        })
      end
    end
  end
end
