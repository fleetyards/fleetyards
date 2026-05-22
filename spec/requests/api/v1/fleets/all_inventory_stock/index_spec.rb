# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/all_inventory_stock", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }

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

    inv1 = create(:fleet_inventory, fleet: fleet, name: "Mining Ops")
    inv2 = create(:fleet_inventory, fleet: fleet, name: "Medical Bay")

    create(:fleet_inventory_item, fleet_inventory: inv1, name: "Quantanium", category: :commodity, quantity: 200, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: inv2, name: "Med Pens", category: :consumable, quantity: 50, unit: :units, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: inv2, name: "Med Pens", category: :consumable, quantity: 10, unit: :units, entry_type: :withdrawal)
  end

  path "/fleets/{fleetSlug}/inventory-stock" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet All Inventory Stock") do
      operationId "fleetAllInventoryStock"
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

          med_pens = data.find { |d| d["name"] == "Med Pens" }
          expect(med_pens["netQuantity"]).to eq(40.0) # 50 - 10
          expect(med_pens["inventory"]["name"]).to eq("Medical Bay")
        end
      end

      include_examples "oauth_auth"
    end
  end
end
