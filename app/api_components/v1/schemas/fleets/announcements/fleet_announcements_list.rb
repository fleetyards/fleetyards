# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Announcements
        class FleetAnnouncementsList
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              items: {
                type: :array,
                items: ::V1::Schemas::Fleets::Announcements::FleetAnnouncement
              }
            },
            required: %w[items]
          })
        end
      end
    end
  end
end
