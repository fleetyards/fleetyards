# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/inventory_items", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_inventory) { create(:fleet_inventory, fleet: fleet) }
  let(:fleetInventorySlug) { fleet_inventory.slug }
  let(:fleet_inventory_item) { create(:fleet_inventory_item, fleet_inventory: fleet_inventory) }
  let(:id) { fleet_inventory_item.id }
  let(:request_body) do
    {
      notes: "Updated after mining run"
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

  path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/items/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"
    parameter name: "id", in: :path, schema: {type: :string}, description: "Inventory item ID"

    put("Update Fleet Inventory Item") do
      operationId "updateFleetInventoryItem"
      tags "FleetInventoryItems"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetInventoryItemUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetInventoryItem"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["notes"]).to eq("Updated after mining run")
        end
      end

      include_examples "oauth_auth"

      response(403, "forbidden - member cannot update items") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { member }

        run_test!
      end
    end
  end
end
