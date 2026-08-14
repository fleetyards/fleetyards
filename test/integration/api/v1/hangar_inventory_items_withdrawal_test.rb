# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryItemsWithdrawalTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @inventory = create(:inventory, holder: @user)
    create(:inventory_item,
      inventory: @inventory,
      name: "Quantanium",
      category: :commodity,
      quantity: 100,
      unit: :scu,
      entry_type: :deposit)
    sign_in @user
  end

  test "successful withdrawal within stock creates a withdrawal entry" do
    post "/api/v1/hangar/inventories/#{@inventory.slug}/items",
      params: {name: "Quantanium", category: "commodity", quantity: 50, unit: "scu", entryType: "withdrawal"},
      as: :json

    assert_equal 201, response.status
    body = JSON.parse(response.body)
    assert_equal "withdrawal", body["entryType"]
    assert_equal 50.0, body["quantity"]
  end

  test "withdrawal exceeding stock is rejected" do
    post "/api/v1/hangar/inventories/#{@inventory.slug}/items",
      params: {name: "Quantanium", category: "commodity", quantity: 200, unit: "scu", entryType: "withdrawal"},
      as: :json

    assert_equal 400, response.status
  end

  test "withdrawal only counts stock from the same inventory" do
    other_inventory = create(:inventory, holder: @user)

    post "/api/v1/hangar/inventories/#{other_inventory.slug}/items",
      params: {name: "Quantanium", category: "commodity", quantity: 10, unit: "scu", entryType: "withdrawal"},
      as: :json

    assert_equal 400, response.status
  end
end
