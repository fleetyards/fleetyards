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
  let(:ship) { create(:mission_ship, :ranged, mission_team: team) }
  let(:id) { ship.id }
  let(:input) { {description: "Updated description"} }

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

  path "/fleets/{fleetSlug}/missions/{missionSlug}/teams/{missionTeamId}/ships/{id}" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "missionSlug", in: :path, type: :string
    parameter name: "missionTeamId", in: :path, type: :string
    parameter name: "id", in: :path, type: :string

    put("Update Mission Ship") do
      operationId "updateMissionShip"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/MissionShipUpdateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/MissionShip"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["description"]).to eq("Updated description")
        end
      end

      include_examples "oauth_auth"
    end
  end
end
