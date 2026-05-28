# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/events/signup", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_event) { create(:fleet_event, :open, fleet: fleet, created_by: admin) }
  let(:slug) { fleet_event.slug }
  let(:user) { member }
  let(:request_body) { {status: "interested"} }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(:oauth_access_token, resource_owner_id: member.id, scopes: ["fleet", "fleet:write"])
  end
  let(:wrong_scope_access_token) do
    create(:oauth_access_token, resource_owner_id: member.id, scopes: ["public"])
  end

  before do
    Flipper.enable("mission_builder")
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/events/{slug}/signup" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    post("Sign up to event without picking a slot") do
      operationId "signupFleetEvent"
      tags "Fleet Event Signups"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FleetEventSignupCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventSignup"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("interested")
          expect(data["fleetEventSlotId"]).to be_nil
        end
      end

      include_examples "oauth_auth", success_status: 201
    end
  end
end
