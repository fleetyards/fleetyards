# frozen_string_literal: true

module V1
  module Schemas
    # The fleet this account's donations support, answerable before any donation
    # exists. `Supporters::Linker` stamps it onto a contribution when one is
    # matched; from then on the contribution carries the authoritative answer.
    class MySupportedFleet
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          # Absent rather than null when there is nothing to show, matching
          # FleetRef everywhere else it is used.
          fleet: ::V1::Schemas::FleetRef,
          # False when the fleet above is the primary-fleet fallback rather than
          # a choice this account made, so the UI can say which it is showing.
          explicit: {type: :boolean}
        },
        required: %w[explicit],
        additionalProperties: false
      })
    end
  end
end
