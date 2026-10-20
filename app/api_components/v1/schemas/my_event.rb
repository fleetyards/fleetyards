# frozen_string_literal: true

module V1
  module Schemas
    # One entry of the reader's agenda. `fleetEvent` and `fleet` are present on
    # a fleet event, `gameEvent` on a curated game event; `startsAt` is the
    # occurrence's start either way, so the list sorts without reaching inside.
    class MyEvent
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          type: ::V1::Schemas::Enums::MyEventTypeEnum,
          startsAt: {type: :string, format: "date-time"},
          fleet: ::V1::Schemas::FleetRef,
          fleetEvent: ::V1::Schemas::Fleets::Events::FleetEvent,
          gameEvent: ::V1::Schemas::GameEvent
        },
        additionalProperties: false,
        required: %w[type startsAt]
      })
    end
  end
end
