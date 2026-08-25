# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # A server-wide announcement. It has no REST counterpart: the payload is
      # the toast the client should show, so these are the AppNotification
      # fields a broadcast is allowed to set. `persist` already expresses "stay
      # until dismissed", so the wire carries no `timeout: false`.
      class AnnouncementMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            text: {type: :string},
            type: {"$ref": "#/components/schemas/AnnouncementTypeEnum"},
            persist: {type: :boolean},
            timeout: {type: :integer},
            background: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[text]
        })
      end
    end
  end
end
