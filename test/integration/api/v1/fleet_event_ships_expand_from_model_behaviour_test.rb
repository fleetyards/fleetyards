# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventShipsExpandFromModelBehaviourTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    @team = create(:fleet_event_team, fleet_event: @event)
    @ship = create(:fleet_event_ship, fleet_event_team: @team)
    @model = create(:model)
    @position1 = create(:model_position, model: @model, name: "Pilot", position: 0)
    @position2 = create(:model_position, model: @model, name: "Gunner 1", position: 1)
    @position3 = create(:model_position, model: @model, name: "Gunner 2", position: 2)
    @url = "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/teams/#{@team.id}/ships/#{@ship.id}/expand-from-model"
    sign_in @admin
  end

  test "creates slots for every position when no positionIds are given" do
    post @url, params: {modelId: @model.id}, as: :json

    assert_equal 200, response.status, "got #{response.status}: #{response.body}"
    assert_equal 3, @ship.fleet_event_slots.count
    assert_equal ["Pilot", "Gunner 1", "Gunner 2"].sort, @ship.fleet_event_slots.pluck(:title).sort
  end

  test "creates only the picked positions when positionIds is provided" do
    post @url, params: {modelId: @model.id, positionIds: [@position2.id]}, as: :json

    assert_equal 200, response.status, "got #{response.status}: #{response.body}"
    assert_equal ["Gunner 1"], @ship.fleet_event_slots.pluck(:title)
  end

  test "skips positions that are already represented as slots" do
    create(:fleet_event_slot, slottable: @ship, model_position_id: @position1.id, title: "Pilot")

    post @url, params: {modelId: @model.id}, as: :json

    assert_equal 200, response.status
    assert_equal 2, @ship.fleet_event_slots.where(model_position_id: [@position2.id, @position3.id]).count
    assert_equal 1, @ship.fleet_event_slots.where(model_position_id: @position1.id).count
  end

  test "returns 422 when there are no new positions to add" do
    [@position1, @position2, @position3].each do |p|
      create(:fleet_event_slot, slottable: @ship, model_position_id: p.id, title: p.name)
    end

    post @url, params: {modelId: @model.id}, as: :json

    assert_equal 422, response.status
  end
end
