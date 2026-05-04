# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/missions", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:input) { {title: "Operation Bluebird", description: "Cargo run"} }

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

  path "/fleets/{fleetSlug}/missions" do
    parameter name: "fleetSlug", in: :path, type: :string

    post("Create Mission") do
      operationId "createFleetMission"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/MissionCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/MissionExtended"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to eq("Operation Bluebird")
          expect(data["slug"]).to eq("operation-bluebird")
        end
      end

      include_examples "oauth_auth", success_status: 201

      response(403, "forbidden - member cannot create") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:user) { member }
        run_test!
      end
    end
  end
end
