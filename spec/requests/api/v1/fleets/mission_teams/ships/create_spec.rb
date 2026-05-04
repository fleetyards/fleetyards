# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/mission_teams/ships", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:mission) { create(:mission, fleet: fleet, created_by: admin) }
  let(:missionSlug) { mission.slug }
  let(:team) { create(:mission_team, mission: mission) }
  let(:missionTeamId) { team.id }
  let(:input) { {classification: "Combat", minSize: "medium"} }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["fleet", "fleet:write"])
  end
  let(:wrong_scope_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["public"])
  end

  before do
    Flipper.enable("mission_builder")
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/missions/{missionSlug}/teams/{missionTeamId}/ships" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "missionSlug", in: :path, type: :string
    parameter name: "missionTeamId", in: :path, type: :string

    post("Create Mission Ship") do
      operationId "createMissionShip"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/MissionShipCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful - range filter") do
        schema "$ref": "#/components/schemas/MissionShip"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["strict"]).to eq(false)
          expect(data["filters"]["classification"]).to eq("Combat")
        end
      end

      response(201, "successful - specific model with materialized seats") do
        schema "$ref": "#/components/schemas/MissionShip"

        let(:model) { create(:model, in_game: true) }
        let!(:positions) do
          [
            create(:model_position, model: model, name: "Pilot", position_type: :pilot, position: 0),
            create(:model_position, model: model, name: "Co-Pilot", position_type: :copilot, position: 1)
          ]
        end
        let(:input) do
          {
            modelId: model.id,
            positionIds: positions.map(&:id)
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["strict"]).to eq(true)
          expect(data["model"]["id"]).to eq(model.id)
          expect(data["slots"].size).to eq(2)
          expect(data["slots"].map { |s| s["title"] }).to match_array(["Pilot", "Co-Pilot"])
          expect(data["slots"].all? { |s| s["derived"] }).to be(true)
        end
      end

      response(400, "bad request - non-in-game model") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:model) { create(:model, in_game: false) }
        let(:input) { {modelId: model.id} }

        run_test!
      end

      include_examples "oauth_auth", success_status: 201
    end
  end
end
