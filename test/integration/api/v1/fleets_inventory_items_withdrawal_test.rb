# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoryItemsWithdrawalTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @inventory = create(:fleet_inventory, fleet: @fleet)
    create(:fleet_inventory_item,
      fleet_inventory: @inventory,
      name: "Quantanium",
      category: :commodity,
      quantity: 100,
      unit: :scu,
      entry_type: :deposit)
    sign_in @admin
  end

  test "successful withdrawal within stock creates a withdrawal entry" do
    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items",
      params: {name: "Quantanium", category: "commodity", quantity: 50, unit: "scu", entryType: "withdrawal"},
      as: :json

    assert_equal 201, response.status
    body = JSON.parse(response.body)
    assert_equal "withdrawal", body["entryType"]
    assert_equal 50.0, body["quantity"]
  end

  test "withdrawal exceeding stock is rejected" do
    post "/api/v1/fleets/#{@fleet.slug}/inventories/#{@inventory.slug}/items",
      params: {name: "Quantanium", category: "commodity", quantity: 200, unit: "scu", entryType: "withdrawal"},
      as: :json

    assert_equal 400, response.status
  end
end
