# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/events/teams/ships", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_event) { create(:fleet_event, fleet: fleet, created_by: admin) }
  let(:fleetEventSlug) { fleet_event.slug }
  let(:team) { create(:fleet_event_team, fleet_event: fleet_event) }
  let(:fleetEventTeamId) { team.id }
  let(:ship) { create(:fleet_event_ship, fleet_event_team: team) }
  let(:id) { ship.id }
  let(:input) { {classification: "Industrial", description: "Hauling"} }

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

  path "/fleets/{fleetSlug}/events/{fleetEventSlug}/teams/{fleetEventTeamId}/ships/{id}" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "fleetEventSlug", in: :path, type: :string
    parameter name: "fleetEventTeamId", in: :path, type: :string
    parameter name: "id", in: :path, type: :string

    put("Update event ship") do
      operationId "updateFleetEventShip"
      tags "Fleet Event Ships"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetEventShipUpdateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventShip"
        run_test!
      end

      include_examples "oauth_auth"
    end

    delete("Destroy event ship") do
      operationId "destroyFleetEventShip"
      tags "Fleet Event Ships"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect { ship.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
