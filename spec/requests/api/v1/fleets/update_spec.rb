# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:user) { admin }
  let(:slug) { fleet.slug }
  let(:request_body) do
    {
      discord: "https://discord.gg/1234567890"
    }
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: admin.id,
      scopes: ["fleet", "fleet:write"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: admin.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{slug}" do
    parameter name: "slug", in: :path, schema: { type: :string }, description: "slug"

    put("Update Fleet") do
      operationId "updateFleet"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["discord"]).to eq("discord.gg/1234567890")
        end
      end

      response(200, "successful with nullable fields") do
        schema "$ref": "#/components/schemas/Fleet"

        let(:request_body) do
          {
            fid: fleet.fid,
            name: fleet.name,
            logo: nil,
            description: "test",
            publicFleet: fleet.public_fleet,
            publicFleetStats: fleet.public_fleet_stats
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["description"]).to eq("test")
        end
      end

      include_examples "oauth_auth"

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-fleet" }

        run_test!
      end

      response(403, "forbidden") do
        description "You are not an Admin or Officer of this Fleet"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { member }

        run_test!
      end

      response(403, "forbidden") do
        description "You are not an Admin or Officer of this Fleet"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user) }

        run_test!
      end
    end
  end
end
