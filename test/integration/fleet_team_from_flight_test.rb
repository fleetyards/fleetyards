# frozen_string_literal: true

require "test_helper"

class FleetTeamFromFlightTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @pilot = create(:user)
    @wingman = create(:user)
    @fleet = create(:fleet, :with_squadrons, admins: [@admin], members: [@pilot, @wingman])
    @squadron = create(:fleet_squadron, fleet: @fleet, flights_enabled: true)
    rows = [@pilot, @wingman].map do |user|
      create(:fleet_squadron_membership, fleet_squadron: @squadron,
        fleet_membership: @fleet.fleet_memberships.kept.find_by!(user:))
    end
    @flight = create(:fleet_squadron_flight, fleet_squadron: @squadron, name: "Strike", description: "Two bombers")
    ship = create(:mission_ship, mission_team: @flight.team, title: "Bomber")
    slot = create(:mission_slot, slottable: ship, title: "Pilot")
    rows.each_with_index { |row, index| slot.mission_slot_candidates.create!(fleet_squadron_membership: row, position: index) }
    sign_in @admin
  end

  test "an event team built from a flight copies the lineup and invites the primary" do
    event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)

    post "/api/v1/fleets/#{@fleet.slug}/events/#{event.slug}/teams", params: {title: "", sourceFlightId: @flight.id}, as: :json

    assert_response :created
    team = event.fleet_event_teams.sole
    assert_equal "Strike", team.title
    assert_equal @squadron.id, team.fleet_squadron_id
    assert_equal @flight.id, team.source_flight_id
    slot = team.fleet_event_ships.sole.fleet_event_slots.sole
    assert_equal [@pilot, @wingman], slot.fleet_event_slot_candidates.map { |c| c.fleet_membership.user }
    assert_equal @pilot, slot.fleet_event_signups.sole.fleet_membership.user
    assert slot.fleet_event_signups.sole.invited?
  end

  test "a draft event keeps the invitation until it is published" do
    event = create(:fleet_event, fleet: @fleet, created_by: @admin)

    post "/api/v1/fleets/#{@fleet.slug}/events/#{event.slug}/teams", params: {title: "Strike", sourceFlightId: @flight.id}, as: :json

    assert_response :created
    assert_empty event.fleet_event_signups

    event.update!(status: "open")

    assert_equal [@pilot], event.fleet_event_signups.map { |signup| signup.fleet_membership.user }
  end

  test "a template team built from a flight keeps the lineup and the list, and passes both to its events" do
    mission = create(:mission, fleet: @fleet)

    post "/api/v1/fleets/#{@fleet.slug}/missions/#{mission.slug}/teams", params: {title: "Strike", sourceFlightId: @flight.id}, as: :json

    assert_response :created
    template_slot = mission.mission_teams.sole.mission_ships.sole.mission_slots.sole
    assert_equal 2, template_slot.mission_slot_candidates.count

    event = FleetEvent.from_mission!(mission, created_by: @admin, starts_at: 2.days.from_now, status: "open")

    assert_equal [@pilot], event.fleet_event_signups.map { |signup| signup.fleet_membership.user }
  end

  test "editing the flight afterwards leaves the event team alone" do
    event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    post "/api/v1/fleets/#{@fleet.slug}/events/#{event.slug}/teams", params: {title: "Strike", sourceFlightId: @flight.id}, as: :json

    @flight.team.mission_ships.destroy_all

    assert_equal 1, event.fleet_event_teams.sole.fleet_event_ships.count
  end

  test "refuses another fleet's flight" do
    event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    foreign = create(:fleet_squadron_flight)

    post "/api/v1/fleets/#{@fleet.slug}/events/#{event.slug}/teams", params: {title: "Strike", sourceFlightId: foreign.id}, as: :json

    assert_response :bad_request
    assert_empty event.fleet_event_teams
  end
  test "refuses a flight whose squadron switched flights off" do
    event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    @squadron.update!(flights_enabled: false)

    post "/api/v1/fleets/#{@fleet.slug}/events/#{event.slug}/teams", params: {title: "Strike", sourceFlightId: @flight.id}, as: :json

    assert_response :bad_request
  end
end
