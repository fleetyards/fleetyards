# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetNotificationInAppEventEnum
        include OpenapiRuby::Components::Base

        # Deliberately not ::FleetNotificationSetting::DEFAULT_IN_APP_EVENTS. That
        # constant lists the events enabled for a new setting; this lists every event
        # a client may enable. They happen to match today.

        VALUES = %w[
          fleet_event.published
          fleet_event.locked
          fleet_event.starting_soon
          fleet_event.cancelled
          fleet_event_signup.created
          fleet_event_signup.withdrawn
        ].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
