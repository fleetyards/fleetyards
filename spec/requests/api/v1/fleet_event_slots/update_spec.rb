# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleet_event_slots", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleet_event) { create(:fleet_event, fleet: fleet, created_by: admin) }
  let(:team) { create(:fleet_event_team, fleet_event: fleet_event) }
  let(:slot) { create(:fleet_event_slot, slottable: team) }
  let(:id) { slot.id }
  let(:input) { {title: "Wing Lead", description: "Squadron lead"} }

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

  path "/fleet-event-slots/{id}" do
    parameter name: "id", in: :path, type: :string

    put("Update event slot") do
      operationId "updateFleetEventSlot"
      tags "Fleet Event Slots"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetEventSlotUpdateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventSlot"
        run_test!
      end

      include_examples "oauth_auth"
    end

    delete("Destroy event slot") do
      operationId "destroyFleetEventSlot"
      tags "Fleet Event Slots"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect { slot.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
