# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/missions", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:mission) { create(:mission, fleet: fleet, created_by: admin) }
  let(:slug) { mission.slug }
  let(:input) { {title: "Updated Mission"} }

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

  path "/fleets/{fleetSlug}/missions/{slug}" do
    parameter name: "fleetSlug", in: :path, type: :string
    parameter name: "slug", in: :path, type: :string

    put("Update Mission") do
      operationId "updateFleetMission"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/MissionUpdateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/MissionExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to eq("Updated Mission")
        end
      end

      include_examples "oauth_auth"
    end
  end
end
