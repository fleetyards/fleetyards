# frozen_string_literal: true

require "test_helper"

# The event side of a hand-picked ship list, and the part that only exists here:
# a spot spawned from a mission has to arrive with the list it was given.
class FleetEventShipAllowedModelsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    Flipper.enable_actor("fleet_mission_builder", @fleet)
    @event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    @team = create(:fleet_event_team, fleet_event: @event)
    @connie = create(:model, name: "Constellation Andromeda", in_game: true)
    @freelancer = create(:model, name: "Freelancer MAX", in_game: true)
    sign_in @admin
  end

  def ships_path
    "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/teams/#{@team.id}/ships"
  end

  test "a list of models is enough on its own to describe a spot" do
    post ships_path,
      params: {title: "Escort", allowedModelIds: [@connie.id, @freelancer.id]},
      as: :json

    assert_response :created
    ship = @team.fleet_event_ships.order(:position).last
    assert_equal [@connie.id, @freelancer.id], ship.allowed_models.map(&:id)
    assert ship.listed?
  end

  test "a list cannot name a ship that is not in the game" do
    concept = create(:model, in_game: false)

    post ships_path,
      params: {title: "Escort", allowedModelIds: [concept.id]},
      as: :json

    assert_response :bad_request
  end

  test "updating with a list replaces it rather than adding to it" do
    ship = create(:fleet_event_ship, fleet_event_team: @team, classification: "combat")
    ship.fleet_event_ship_models.create!(model_id: @connie.id, position: 0)

    patch "#{ships_path}/#{ship.id}",
      params: {allowedModelIds: [@freelancer.id]},
      as: :json

    assert_response :success
    assert_equal [@freelancer.id], ship.reload.allowed_models.map(&:id)
  end

  # The factory gives a ship filters, which satisfied model_or_filter_required on
  # its own and so hid an ordering bug: a spot whose whole spec is a list has
  # nothing in its columns.
  test "an event spawns from a mission spot whose whole spec is a list" do
    mission = create(:mission, fleet: @fleet, created_by: @admin)
    mission_team = create(:mission_team, mission: mission)
    listed = MissionShip.new(mission_team: mission_team, title: "Listed", position: 0)
    listed.mission_ship_models.build(model_id: @connie.id, position: 0)
    listed.save!

    event = FleetEvent.from_mission!(
      mission,
      created_by: @admin,
      starts_at: 2.days.from_now,
      timezone: "UTC"
    )

    spawned = event.fleet_event_teams.first.fleet_event_ships.first
    assert_equal [@connie.id], spawned.allowed_models.map(&:id)
    assert_nil spawned.classification
  end

  test "an event spawned from a mission carries each spot's list" do
    mission = create(:mission, fleet: @fleet, created_by: @admin)
    mission_team = create(:mission_team, mission: mission)
    mission_ship = create(:mission_ship, mission_team: mission_team)
    mission_ship.mission_ship_models.create!(model_id: @connie.id, position: 0)
    mission_ship.mission_ship_models.create!(model_id: @freelancer.id, position: 1)

    event = FleetEvent.from_mission!(
      mission,
      created_by: @admin,
      starts_at: 2.days.from_now,
      timezone: "UTC"
    )

    spawned = event.fleet_event_teams.first.fleet_event_ships.first
    assert_equal [@connie.id, @freelancer.id], spawned.allowed_models.map(&:id)
  end

  test "retiring a model drops it from the lists that named it" do
    ship = create(:fleet_event_ship, fleet_event_team: @team)
    ship.fleet_event_ship_models.create!(model_id: @connie.id, position: 0)
    ship.fleet_event_ship_models.create!(model_id: @freelancer.id, position: 1)

    @connie.destroy

    assert_equal [@freelancer.id], ship.reload.allowed_models.map(&:id)
  end
end
