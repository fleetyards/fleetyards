# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/events/teams/ships/expand-from-model", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_event) { create(:fleet_event, fleet: fleet, created_by: admin) }
  let(:fleetEventSlug) { fleet_event.slug }
  let(:team) { create(:fleet_event_team, fleet_event: fleet_event) }
  let(:fleetEventTeamId) { team.id }
  let(:model) { create(:model) }
  let(:ship) { create(:fleet_event_ship, fleet_event_team: team) }
  let(:id) { ship.id }
  let(:input) { {model_id: model.id} }

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

  path "/fleets/{fleetSlug}/events/{fleetEventSlug}/teams/{fleetEventTeamId}/ships/{id}/expand-from-model" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "fleetEventSlug", in: :path, type: :string
    parameter name: "fleetEventTeamId", in: :path, type: :string
    parameter name: "id", in: :path, type: :string

    post("Expand ship slots from model positions") do
      operationId "expandFleetEventShipFromModel"
      tags "Fleet Event Ships"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {
          modelId: {type: :string, format: :uuid},
          positionIds: {type: :array, items: {type: :string, format: :uuid}}
        },
        required: %w[modelId]
      }, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        let(:position) { create(:model_position, model: model) }

        before do
          position
        end

        schema "$ref": "#/components/schemas/FleetEventShip"
        run_test!
      end

      response(422, "no new positions to add") do
        run_test!
      end

      include_examples "oauth_auth"
    end
  end
end
