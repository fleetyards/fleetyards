# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      class HangarSyncFailedMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            status: Cable::V1::Schemas::Enums::HangarSyncFailedStatusEnum,
            error: {type: :string}
          },
          additionalProperties: false,
          required: %w[status error]
        })
      end
    end
  end
end
