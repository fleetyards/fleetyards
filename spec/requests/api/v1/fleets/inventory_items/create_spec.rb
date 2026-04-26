# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/inventory_items", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:officer) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], officers: [officer], members: [member]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_inventory) { create(:fleet_inventory, fleet: fleet) }
  let(:fleetInventorySlug) { fleet_inventory.slug }
  let(:input) do
    {
      name: "Quantanium",
      category: "commodity",
      quantity: 250.5,
      unit: "scu"
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

  path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/items" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, type: :string, description: "Inventory slug"

    post("Create Fleet Inventory Item") do
      operationId "createFleetInventoryItem"
      tags "FleetInventoryItems"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetInventoryItemCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetInventoryItem"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Quantanium")
          expect(data["quantity"]).to eq(250.5)
        end
      end

      include_examples "oauth_auth", success_status: 201

      response(201, "successful as officer") do
        schema "$ref": "#/components/schemas/FleetInventoryItem"

        let(:user) { officer }

        run_test!
      end

      response(403, "forbidden - member cannot add items") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { member }

        run_test!
      end
    end
  end
end
