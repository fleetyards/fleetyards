# frozen_string_literal: true

require "test_helper"

class FleetSquadronFlightTest < ActiveSupport::TestCase
  test "a new flight comes with its lead seat" do
    flight = create(:fleet_squadron_flight)

    lead = flight.team.mission_slots.sole
    assert lead.lead?
    assert_equal "Flight lead", lead.title
  end

  test "the lead seat cannot be removed on its own" do
    lead = create(:fleet_squadron_flight).team.mission_slots.sole

    assert_not lead.destroy
    assert_includes lead.errors.details[:base], {error: :lead_required}
  end

  test "the lead seat goes with the flight" do
    flight = create(:fleet_squadron_flight)
    lead_id = flight.team.mission_slots.sole.id

    flight.destroy!

    assert_not MissionSlot.exists?(lead_id)
  end

  test "the lead seat heads the list" do
    team = create(:fleet_squadron_flight).team
    create(:mission_slot, slottable: team, title: "Comms", position: -5)

    assert_equal [true, false], team.mission_slots.reload.map(&:lead?)
  end

  test "an event team built from a flight gets its lead" do
    flight = create(:fleet_squadron_flight)
    event = create(:fleet_event, fleet: flight.fleet)

    team = event.fleet_event_teams.create!(title: "Strike", source_flight: flight)

    assert team.fleet_event_slots.sole.lead?
  end
end
