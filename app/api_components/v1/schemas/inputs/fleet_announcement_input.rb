# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetAnnouncementInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            body: {type: :string, maxLength: ::FleetAnnouncement::BODY_LIMIT},
            expiresAt: {type: [:string, :null], format: "date-time"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
