# frozen_string_literal: true

# Which of a fleet's events the caller reaches: whoever runs the fleet's events
# reaches all of them, everyone else those of their squadrons.
module FleetEventScoped
  extend ActiveSupport::Concern

  private def reachable_fleet_events(scope = @fleet.fleet_events)
    allowed_to?(:manage?, @fleet, with: FleetEventPolicy) ? scope : narrow_to_squadron_access(scope)
  end
end
