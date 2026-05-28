# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/events", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:request_body) do
    {
      title: "Patrol Run",
      startsAt: 2.days.from_now.iso8601,
      timezone: "UTC",
      visibility: "members",
      autoLockEnabled: false
    }
  end

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

  path "/fleets/{fleetSlug}/events" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    post("Create Fleet Event") do
      operationId "createFleetEvent"
      tags "Fleet Events"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FleetEventCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to eq("Patrol Run")
          expect(data["status"]).to eq("draft")
        end
      end

      include_examples "oauth_auth", success_status: 201

      response(403, "forbidden - member cannot create") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:user) { member }
        run_test!
      end
    end
  end
end
