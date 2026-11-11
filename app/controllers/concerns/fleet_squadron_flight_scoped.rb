# frozen_string_literal: true

# The fleet, squadron and flight a flight's ships and slots hang off, for the
# controllers that reuse the template editor's actions. Flights are a squadron
# feature, so they answer to the squadron switch rather than to the template
# builder and its subscription.
module FleetSquadronFlightScoped
  extend ActiveSupport::Concern
  include FleetSquadronScoped

  included do
    skip_before_action :check_fleet_mission_builder_feature
    skip_before_action :require_events_subscription
  end

  private def load_flight!
    @fleet ||= authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
    authorize! @fleet, to: :show?

    @fleet_squadron = readable_fleet_squadrons.find_by!(slug: params[:fleet_squadron_slug])
    @flight = @fleet_squadron.fleet_squadron_flights.find(params[:fleet_squadron_flight_id])
  end

  private def check_flight_squadrons_feature
    check_fleet_squadrons_feature
  end

  private def authorize_flight!
    authorize! @flight, with: FleetSquadronFlightPolicy, to: :update?, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}
  end
end
