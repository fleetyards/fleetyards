# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/mission_teams", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:mission) { create(:mission, fleet: fleet, created_by: admin) }
  let(:missionSlug) { mission.slug }
  let(:input) { {title: "Strike Team", description: "Main combat group"} }

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

  path "/fleets/{fleetSlug}/missions/{missionSlug}/teams" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "missionSlug", in: :path, type: :string

    post("Create Mission Team") do
      operationId "createMissionTeam"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/MissionTeamCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/MissionTeam"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to eq("Strike Team")
          expect(data["position"]).to eq(0)
        end
      end

      include_examples "oauth_auth", success_status: 201
    end
  end
end
