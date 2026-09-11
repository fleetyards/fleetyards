# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # A run the user stopped. It carries the same result body as a finished
      # one -- the counts are of what it managed before it stopped, which is
      # exactly what the user needs to see after cancelling.
      class HangarSyncCancelledMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            status: Cable::V1::Schemas::Enums::HangarSyncCancelledStatusEnum,
            result: ::V1::Schemas::Hangar::HangarSyncResult
          },
          additionalProperties: false,
          required: %w[status result]
        })
      end
    end
  end
end
