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

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: admin.id,
      scopes: ["fleet", "fleet:read"]
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

    create_list(:fleet_inventory_item, 3, fleet_inventory: fleet_inventory)
  end

  path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/items" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, type: :string, description: "Inventory slug"

    get("Fleet Inventory Items List") do
      operationId "fleetInventoryItems"
      tags "FleetInventoryItems"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetInventoryItem.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetInventoryItemQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetInventoryItemsList"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
      end

      include_examples "oauth_auth"
    end
  end
end
