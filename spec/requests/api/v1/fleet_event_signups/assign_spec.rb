# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleet_event_signups/assign", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:fleet_event) { create(:fleet_event, :open, fleet: fleet, created_by: admin) }
  let(:fleet_event_team) { create(:fleet_event_team, fleet_event: fleet_event) }
  let(:fleet_event_slot) { create(:fleet_event_slot, slottable: fleet_event_team) }
  let(:other_slot) { create(:fleet_event_slot, slottable: fleet_event_team) }
  let(:user) { admin }

  let(:signup) do
    membership = fleet.fleet_memberships.find_by(user: member)
    create(:fleet_event_signup,
      fleet_event: fleet_event,
      fleet_event_slot: nil,
      fleet_membership: membership,
      status: "interested")
  end
  let(:id) { signup.id }
  let(:input) { {fleetEventSlotId: other_slot.id, status: "confirmed"} }

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

  path "/fleet-event-signups/{id}/assign" do
    parameter name: "id", in: :path, type: :string

    patch("Admin: assign or update a signup") do
      operationId "assignFleetEventSignup"
      tags "Fleet Event Signups"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetEventSignupAssignInput"}, required: true

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
          expect(data["fleetEventSlotId"]).to eq(other_slot.id)
        end
      end

      include_examples "oauth_auth"
    end
  end
end
