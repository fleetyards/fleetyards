# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/events/admins", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:other) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [other]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_event) { create(:fleet_event, fleet: fleet, created_by: admin) }
  let(:slug) { fleet_event.slug }
  let(:input) { {userId: other.id, role: "admin"} }

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

  path "/fleets/{fleetSlug}/events/{slug}/admins" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    post("Grant per-event admin/moderator role") do
      operationId "createFleetEventAdmin"
      tags "Fleet Event Admins"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetEventAdminCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventAdmin"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["role"]).to eq("admin")
        end
      end

      include_examples "oauth_auth", success_status: 201
    end
  end
end
