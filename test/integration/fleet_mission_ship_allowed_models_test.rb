# frozen_string_literal: true

require "test_helper"

# A ship spot names one exact model, a list of models it will take, or the
# criteria a model has to meet. This covers the middle one, which is the only
# kind whose answer lives in rows rather than columns.
class FleetMissionShipAllowedModelsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    Flipper.enable_actor("fleet_mission_builder", @fleet)
    @mission = create(:mission, fleet: @fleet, created_by: @admin)
    @team = create(:mission_team, mission: @mission)
    @connie = create(:model, :in_game, name: "Constellation Andromeda")
    @freelancer = create(:model, :in_game, name: "Freelancer MAX")
    sign_in @admin
  end

  def ships_path
    "/api/v1/fleets/#{@fleet.slug}/missions/#{@mission.slug}/teams/#{@team.id}/ships"
  end

  test "a list of models is enough on its own to describe a spot" do
    post ships_path,
      params: {title: "Escort", allowedModelIds: [@connie.id, @freelancer.id]},
      as: :json

    assert_response :created
    ship = @team.mission_ships.order(:position).last
    assert_equal [@connie.id, @freelancer.id], ship.allowed_models.map(&:id)
    assert ship.listed?
    assert_not ship.strict?
    assert_not ship.filtered?
  end

  test "the order the models were picked in is the order they come back" do
    post ships_path,
      params: {title: "Escort", allowedModelIds: [@freelancer.id, @connie.id]},
      as: :json

    assert_response :created
    ship = @team.mission_ships.order(:position).last
    assert_equal ["Freelancer MAX", "Constellation Andromeda"], ship.allowed_models.map(&:name)
  end

  test "a spot with neither a model, a list nor a filter is rejected" do
    post ships_path, params: {title: "Escort"}, as: :json

    assert_response :bad_request
  end

  test "a list cannot name a ship that is not in the game" do
    concept = create(:model)

    post ships_path,
      params: {title: "Escort", allowedModelIds: [concept.id]},
      as: :json

    assert_response :bad_request
  end

  test "updating with a list replaces it rather than adding to it" do
    ship = create(:mission_ship, mission_team: @team, classification: "combat")
    ship.mission_ship_models.create!(model_id: @connie.id, position: 0)

    patch "#{ships_path}/#{ship.id}",
      params: {allowedModelIds: [@freelancer.id]},
      as: :json

    assert_response :success
    assert_equal [@freelancer.id], ship.reload.allowed_models.map(&:id)
  end

  test "an update that does not mention the list leaves it alone" do
    ship = create(:mission_ship, mission_team: @team)
    ship.mission_ship_models.create!(model_id: @connie.id, position: 0)

    patch "#{ships_path}/#{ship.id}", params: {title: "Renamed"}, as: :json

    assert_response :success
    assert_equal "Renamed", ship.reload.title
    assert_equal [@connie.id], ship.allowed_models.map(&:id)
  end

  # The factory gives a ship filters, which satisfied model_or_filter_required on
  # its own and so hid an ordering bug: a spot whose whole spec is a list has
  # nothing in its columns.
  def listed_ship(*model_ids)
    ship = MissionShip.new(mission_team: @team, title: "Listed", position: 0)
    model_ids.each_with_index do |id, index|
      ship.mission_ship_models.build(model_id: id, position: index)
    end
    ship.save!
    ship
  end

  test "duplicating a spot whose whole spec is a list" do
    ship = listed_ship(@connie.id, @freelancer.id)

    post "#{ships_path}/#{ship.id}/duplicate"

    assert_response :created
    copy = @team.mission_ships.order(:position).last
    assert_not_equal ship.id, copy.id
    assert_equal [@connie.id, @freelancer.id], copy.allowed_models.map(&:id)
    assert_nil copy.classification
  end

  test "a spot that says nothing at all reports it rather than raising" do
    post ships_path, params: {title: "Empty"}, as: :json

    assert_response :bad_request
    assert_includes response.body.downcase, "ship"
  end

  test "duplicating a spot carries its list" do
    ship = create(:mission_ship, mission_team: @team)
    ship.mission_ship_models.create!(model_id: @connie.id, position: 0)
    ship.mission_ship_models.create!(model_id: @freelancer.id, position: 1)

    post "#{ships_path}/#{ship.id}/duplicate"

    assert_response :created
    copy = @team.mission_ships.order(:position).last
    assert_not_equal ship.id, copy.id
    assert_equal [@connie.id, @freelancer.id], copy.allowed_models.map(&:id)
  end

  test "retiring a model drops it from the lists that named it" do
    ship = create(:mission_ship, mission_team: @team)
    ship.mission_ship_models.create!(model_id: @connie.id, position: 0)
    ship.mission_ship_models.create!(model_id: @freelancer.id, position: 1)

    @connie.destroy

    assert_equal [@freelancer.id], ship.reload.allowed_models.map(&:id)
  end
end
