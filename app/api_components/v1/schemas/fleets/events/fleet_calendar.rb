# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetCalendar
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              items: {
                type: :array,
                items: ::V1::Schemas::Fleets::Events::FleetEvent
              }
            },
            required: %w[items]
          })
        end
      end
    end
  end
end
