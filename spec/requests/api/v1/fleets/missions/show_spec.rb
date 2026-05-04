# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/missions", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:mission) { create(:mission, fleet: fleet, created_by: admin) }
  let(:slug) { mission.slug }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["fleet", "fleet:read"])
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

    get("Show Mission") do
      operationId "fleetMission"
      tags "Missions"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/MissionExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to eq(mission.title)
          expect(data["teams"]).to be_an(Array)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:slug) { "missing-mission" }
        run_test!
      end

      include_examples "oauth_auth"
    end
  end
end
