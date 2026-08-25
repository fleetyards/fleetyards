# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # HangarChannel carries two things: the vehicle that changed, and a ping
      # for a hangar group whose membership moved without any one vehicle
      # changing. Subscribers refetch either way, so the ping needs no payload —
      # but it needs a shape no vehicle can satisfy, or declaring it as an
      # alternative would stop the vehicle contract being enforced at all.
      class HangarGroupChangedMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            hangarGroupId: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: %w[hangarGroupId]
        })
      end
    end
  end
end
