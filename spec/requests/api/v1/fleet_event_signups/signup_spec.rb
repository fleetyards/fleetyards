# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleet_event_signups", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:fleet_event) { create(:fleet_event, :open, fleet: fleet, created_by: admin) }
  let(:fleet_event_team) { create(:fleet_event_team, fleet_event: fleet_event) }
  let(:fleet_event_slot) { create(:fleet_event_slot, slottable: fleet_event_team) }
  let(:user) { member }
  let(:id) { fleet_event_slot.id }
  let(:input) { {status: "confirmed", notes: "Ready"} }

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

  path "/fleet-event-slots/{id}/signup" do
    parameter name: "id", in: :path, type: :string

    post("Sign up for slot") do
      operationId "signupFleetEventSlot"
      tags "Fleet Event Signups"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetEventSignupCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventSignup"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("confirmed")
          expect(data["notes"]).to eq("Ready")
        end
      end

      include_examples "oauth_auth", success_status: 201
    end

    patch("Update own signup") do
      operationId "updateFleetEventSignup"
      tags "Fleet Event Signups"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetEventSignupUpdateInput"}, required: true

      let(:input) { {status: "confirmed"} }
      before do
        membership = fleet.fleet_memberships.find_by(user: member)
        create(:fleet_event_signup, fleet_event_slot: fleet_event_slot, fleet_membership: membership, status: "pending")
      end

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventSignup"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("confirmed")
        end
      end

      include_examples "oauth_auth"
    end

    delete("Withdraw own signup") do
      operationId "withdrawFleetEventSignup"
      tags "Fleet Event Signups"
      produces "application/json"

      before do
        membership = fleet.fleet_memberships.find_by(user: member)
        create(:fleet_event_signup, fleet_event_slot: fleet_event_slot, fleet_membership: membership, status: "confirmed")
      end

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
        run_test!
      end

      include_examples "oauth_auth", success_status: 204
    end
  end

  path "/fleet-event-signups/{id}" do
    parameter name: "id", in: :path, type: :string

    let(:user) { admin }
    let(:oauth_access_token) do
      create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["fleet", "fleet:write"])
    end
    let(:signup) do
      membership = fleet.fleet_memberships.find_by(user: member)
      create(:fleet_event_signup, fleet_event_slot: fleet_event_slot, fleet_membership: membership)
    end
    let(:id) { signup.id }

    delete("Withdraw a member's signup (admin)") do
      operationId "destroyFleetEventSignup"
      tags "Fleet Event Signups"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect(signup.reload.status).to eq("withdrawn")
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
