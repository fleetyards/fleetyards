# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/mission_teams", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:mission) { create(:mission, fleet: fleet, created_by: admin) }
  let(:missionSlug) { mission.slug }
  let!(:teams) { create_list(:mission_team, 3, mission: mission) }
  let(:input) { {sorting: teams.reverse.map(&:id)} }

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

  path "/fleets/{fleetSlug}/missions/{missionSlug}/teams/sort" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "missionSlug", in: :path, type: :string

    put("Sort Mission Teams") do
      operationId "sortMissionTeams"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/SortInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema type: :object, properties: {success: {type: :boolean}}

        run_test! do
          teams.reverse.each_with_index do |team, index|
            expect(team.reload.position).to eq(index)
          end
        end
      end

      include_examples "oauth_auth"
    end
  end
end
