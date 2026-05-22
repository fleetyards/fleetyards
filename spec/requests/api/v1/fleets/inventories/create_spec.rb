# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/inventories", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:request_body) do
    {
      name: "Mining Stockpile",
      description: "Resources from mining operations",
      visibility: "members_only"
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
    Flipper.enable("fleet_logistics")
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/inventories" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    post("Create Fleet Inventory") do
      operationId "createFleetInventory"
      tags "FleetInventories"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetInventoryCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetInventory"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Mining Stockpile")
          expect(data["slug"]).to be_present
        end
      end

      include_examples "oauth_auth", success_status: 201

      response(400, "bad request - duplicate name") do
        schema "$ref": "#/components/schemas/ValidationError"

        before do
          create(:fleet_inventory, fleet: fleet, name: "Mining Stockpile")
        end

        run_test!
      end

      response(403, "forbidden - member cannot create") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { member }

        run_test!
      end
    end
  end
end
