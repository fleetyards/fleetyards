# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FleetEventShip expand_from_model", type: :request do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:event) { create(:fleet_event, :open, fleet: fleet, created_by: admin) }
  let(:team) { create(:fleet_event_team, fleet_event: event) }
  let(:ship) { create(:fleet_event_ship, fleet_event_team: team) }
  let(:model) { create(:model) }
  let!(:position1) { create(:model_position, model: model, name: "Pilot", position: 0) }
  let!(:position2) { create(:model_position, model: model, name: "Gunner 1", position: 1) }
  let!(:position3) { create(:model_position, model: model, name: "Gunner 2", position: 2) }
  let(:url) do
    "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/teams/#{team.id}/ships/#{ship.id}/expand-from-model"
  end

  before do
    Flipper.enable("mission_builder")
    sign_in(admin)
  end

  it "creates slots for every position when no positionIds are given" do
    post url, params: {modelId: model.id}, as: :json
    expect(response).to have_http_status(:ok), "got #{response.status}: #{response.body}"
    expect(ship.fleet_event_slots.count).to eq(3)
    expect(ship.fleet_event_slots.pluck(:title)).to match_array(["Pilot", "Gunner 1", "Gunner 2"])
  end

  it "creates only the picked positions when positionIds is provided" do
    post url, params: {modelId: model.id, positionIds: [position2.id]}, as: :json
    expect(response).to have_http_status(:ok), "got #{response.status}: #{response.body}"
    expect(ship.fleet_event_slots.pluck(:title)).to eq(["Gunner 1"])
  end

  it "skips positions that are already represented as slots" do
    create(:fleet_event_slot, slottable: ship, model_position_id: position1.id, title: "Pilot")

    post url, params: {modelId: model.id}, as: :json
    expect(response).to have_http_status(:ok)
    expect(ship.fleet_event_slots.where(model_position_id: [position2.id, position3.id]).count).to eq(2)
    expect(ship.fleet_event_slots.where(model_position_id: position1.id).count).to eq(1)
  end

  it "returns 422 when there are no new positions to add" do
    [position1, position2, position3].each do |p|
      create(:fleet_event_slot, slottable: ship, model_position_id: p.id, title: p.name)
    end

    post url, params: {modelId: model.id}, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
