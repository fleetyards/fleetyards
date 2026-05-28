# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/events/teams", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_event) { create(:fleet_event, fleet: fleet, created_by: admin) }
  let(:fleetEventSlug) { fleet_event.slug }
  let(:request_body) { {title: "Strike Team", description: "Heavy fighters"} }

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

  path "/fleets/{fleetSlug}/events/{fleetEventSlug}/teams" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventSlug", in: :path, schema: {type: :string}

    post("Create event team") do
      operationId "createFleetEventTeam"
      tags "Fleet Event Teams"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FleetEventTeamCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventTeam"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to eq("Strike Team")
        end
      end

      include_examples "oauth_auth", success_status: 201
    end
  end
end
