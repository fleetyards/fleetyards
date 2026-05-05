# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleet_event_slots/sort", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleet_event) { create(:fleet_event, fleet: fleet, created_by: admin) }
  let(:team) { create(:fleet_event_team, fleet_event: fleet_event) }
  let(:slots) { create_list(:fleet_event_slot, 3, slottable: team) }
  let(:input) do
    {
      slottableType: "FleetEventTeam",
      slottableId: team.id,
      sorting: slots.reverse.map(&:id)
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

  path "/fleet-event-slots/sort" do
    put("Sort event slots") do
      operationId "sortFleetEventSlots"
      tags "Fleet Event Slots"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {
          slottableType: {type: :string, enum: %w[FleetEventTeam FleetEventShip]},
          slottableId: {type: :string, format: :uuid},
          sorting: {type: :array, items: {type: :string, format: :uuid}}
        },
        required: %w[slottableType slottableId sorting]
      }, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        run_test!
      end

      include_examples "oauth_auth"
    end
  end
end
