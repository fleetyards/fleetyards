# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/inventory_stock", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_inventory) { create(:fleet_inventory, fleet: fleet) }
  let(:fleetInventorySlug) { fleet_inventory.slug }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["fleet", "fleet:read"])
  end
  let(:wrong_scope_access_token) do
    create(:oauth_access_token, resource_owner_id: admin.id, scopes: ["public"])
  end

  before do
    Flipper.enable("fleet_logistics")
    sign_in(user) if user.present?

    create(:fleet_inventory_item, fleet_inventory: fleet_inventory, name: "Quantanium", category: :commodity, quantity: 100, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: fleet_inventory, name: "Quantanium", category: :commodity, quantity: 50, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: fleet_inventory, name: "Quantanium", category: :commodity, quantity: 30, unit: :scu, entry_type: :withdrawal)
    create(:fleet_inventory_item, fleet_inventory: fleet_inventory, name: "Medical Supplies", category: :consumable, quantity: 10, unit: :units, entry_type: :deposit)
  end

  path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/stock" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, type: :string, description: "Inventory slug"

    get("Fleet Inventory Stock") do
      operationId "fleetInventoryStock"
      tags "FleetInventoryStock"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/FleetInventoryStockItem"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.length).to eq(2)

          quantanium = data.find { |d| d["name"] == "Quantanium" }
          expect(quantanium["netQuantity"]).to eq(120.0) # 100 + 50 - 30

          medical = data.find { |d| d["name"] == "Medical Supplies" }
          expect(medical["netQuantity"]).to eq(10.0)
        end
      end

      include_examples "oauth_auth"
    end
  end
end
