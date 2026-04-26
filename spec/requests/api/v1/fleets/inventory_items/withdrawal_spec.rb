# frozen_string_literal: true

require "rails_helper"

RSpec.describe "api/v1/fleets/inventory_items withdrawal", type: :request do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:fleet_inventory) { create(:fleet_inventory, fleet: fleet) }

  before do
    Flipper.enable("fleet_logistics")
    sign_in(admin)

    create(:fleet_inventory_item, fleet_inventory: fleet_inventory, name: "Quantanium", category: :commodity, quantity: 100, unit: :scu, entry_type: :deposit)
  end

  describe "successful withdrawal within stock" do
    it "creates a withdrawal entry" do
      post "/api/v1/fleets/#{fleet.slug}/inventories/#{fleet_inventory.slug}/items",
        params: {name: "Quantanium", category: "commodity", quantity: 50, unit: "scu", entryType: "withdrawal"},
        as: :json

      expect(response).to have_http_status(:created)

      data = JSON.parse(response.body)
      expect(data["entryType"]).to eq("withdrawal")
      expect(data["quantity"]).to eq(50.0)
    end
  end

  describe "withdrawal exceeding stock is rejected" do
    it "returns bad request" do
      post "/api/v1/fleets/#{fleet.slug}/inventories/#{fleet_inventory.slug}/items",
        params: {name: "Quantanium", category: "commodity", quantity: 200, unit: "scu", entryType: "withdrawal"},
        as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end
end
