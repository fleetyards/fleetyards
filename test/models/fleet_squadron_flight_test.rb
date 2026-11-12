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
  test "a flight's ship always has a pilot seat" do
    team = create(:fleet_squadron_flight).team

    ship = create(:mission_ship, mission_team: team)

    assert_equal ["pilot"], ship.mission_slots.reload.map(&:role)
  end

  test "a flight's ship is flown by its owner and is their ship's model" do
    ship = create(:mission_ship, mission_team: create(:fleet_squadron_flight).team)

    assert_equal ship.vehicle.model_id, ship.model_id
    pilot = ship.mission_slots.reload.sole.mission_slot_candidates.sole
    assert_equal ship.vehicle.user_id, pilot.fleet_squadron_membership.fleet_membership.user_id
    assert_equal ship.vehicle_id, pilot.vehicle_id
  end

  test "a flight's ship hands its pilot seat to the new owner when it changes hands" do
    ship = create(:mission_ship, mission_team: create(:fleet_squadron_flight).team)
    squadron = ship.flight.fleet_squadron
    row = create(:fleet_squadron_membership, fleet_squadron: squadron)
    other = create(:vehicle, user: row.fleet_membership.user, model: create(:model, :in_game))
    FleetVehicle.create!(fleet_id: squadron.fleet_id, vehicle_id: other.id)

    ship.update!(vehicle: other)

    pilot = ship.mission_slots.find_by!(role: "pilot").mission_slot_candidates.sole
    assert_equal row.id, pilot.fleet_squadron_membership_id
    assert_equal other.id, pilot.vehicle_id
  end

  test "a flight's ship has to be one the fleet lists" do
    ship = create(:mission_ship, mission_team: create(:fleet_squadron_flight).team)

    ship.vehicle = create(:vehicle, user: ship.vehicle.user, model: create(:model, :in_game))

    assert_not ship.valid?
    assert ship.errors.added?(:vehicle_id, :not_in_squadron)
  end

  test "a template's ship cannot name a member's ship" do
    ship = build(:mission_ship, vehicle: create(:vehicle))

    assert_not ship.valid?
    assert ship.errors.added?(:vehicle_id, :present)
  end

  test "renaming a flight renames its team" do
    flight = create(:fleet_squadron_flight, name: "Alpha")

    flight.update!(name: "Bravo")

    assert_equal "Bravo", flight.team.reload.title
  end

  test "a flight's ship has to name a member's ship" do
    ship = build(:mission_ship, mission_team: create(:fleet_squadron_flight).team)
    ship.vehicle = nil

    assert_not ship.valid?
    assert ship.errors.added?(:vehicle_id, :blank)
  end

  test "a ship's last pilot seat cannot be removed on its own" do
    ship = create(:mission_ship, mission_team: create(:fleet_squadron_flight).team)
    pilot = ship.mission_slots.sole

    assert_not pilot.destroy
    assert_includes pilot.errors.details[:base], {error: :pilot_required}

    ship.mission_slots.create!(role: "pilot", title: "Second pilot")
    assert pilot.reload.destroy
  end

  test "captain and pilot seats head a ship's seats" do
    ship = create(:mission_ship, mission_team: create(:fleet_squadron_flight).team)
    create(:mission_slot, slottable: ship, title: "Gunner", position: -10)
    create(:mission_slot, slottable: ship, title: "Captain", role: "captain", position: 9)

    assert_equal %w[captain pilot] + [nil], ship.mission_slots.reload.map(&:role)
  end

  test "a template's ship gets no pilot seat it was not given" do
    ship = create(:mission_ship)

    assert_empty ship.mission_slots.reload
  end
  test "a seat named after a role in any language takes it" do
    ship = create(:mission_ship, mission_team: create(:fleet_squadron_flight).team)

    assert_equal "captain", ship.mission_slots.create!(title: "Kapitän").role
    assert_equal "pilot", ship.mission_slots.create!(title: " pilot ").role
    assert_nil ship.mission_slots.create!(title: "Co-Pilot").role
  end

  test "a model's captain position is the captain" do
    position = create(:model_position, name: "Captain", position_type: :operator)
    ship = create(:mission_ship, mission_team: create(:fleet_squadron_flight).team)

    assert_equal "captain", ship.mission_slots.create!(title: "Bridge", model_position: position).role
  end
end
