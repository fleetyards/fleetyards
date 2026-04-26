# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/inventory_items", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:fleet_inventory) { create(:fleet_inventory, fleet: fleet) }
  let(:fleetInventorySlug) { fleet_inventory.slug }
  let(:fleet_inventory_item) { create(:fleet_inventory_item, fleet_inventory: fleet_inventory) }
  let(:id) { fleet_inventory_item.id }

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

    fleet_inventory_item
  end

  path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/items/{id}" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, type: :string, description: "Inventory slug"
    parameter name: "id", in: :path, type: :string, description: "Inventory item ID"

    delete("Delete Fleet Inventory Item") do
      operationId "destroyFleetInventoryItem"
      tags "FleetInventoryItems"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect(FleetInventoryItem.find_by(id: fleet_inventory_item.id)).to be_nil
        end
      end

      include_examples "oauth_auth", success_status: 204

      response(403, "forbidden - member cannot delete items") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { member }

        run_test!
      end
    end
  end
end
