# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Announcements
        class FleetAnnouncement
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              body: {type: :string},
              expiresAt: {type: [:string, :null], format: "date-time"},
              author: {anyOf: [::V1::Schemas::UserRefWithAvatar, {type: :null}]},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            required: %w[id body createdAt updatedAt]
          })
        end
      end
    end
  end
end
