# frozen_string_literal: true

require "asyncapi_helper"

class HangarInventoryChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "hangar_inventory:{user_gid}", channel_class: HangarInventoryChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "Something in one of the user's own inventories changed" do
      operationId "receiveHangarInventoryUpdate"
      message ::Cable::V1::Schemas::HangarInventoryChangedMessage
    end
  end

  setup do
    @user = create(:user)
    @inventory = create(:inventory, holder: @user)
  end

  test "broadcasts when an entry is added" do
    payloads = assert_asyncapi_broadcast(params: {user_gid: @user.to_gid_param}) do
      create(:inventory_item, inventory: @inventory)
    end

    assert_equal @inventory.id, payloads.first["inventoryId"]
    assert_equal @inventory.slug, payloads.first["inventorySlug"]
  end

  # The case a hook on the entry would miss: `move_position` renames through
  # `update_all`, which runs no callbacks, and only the inventory's own touch
  # is left to notice.
  test "broadcasts when a position is renamed" do
    create(:inventory_item, inventory: @inventory,
      name: "Ore", category: :commodity, unit: :scu, quantity: 5, entry_type: :deposit)
    stock_item = @inventory.stock_item(
      InventoryStockItem.slug_for(name: "Ore", category: "commodity", unit: "scu")
    )

    payloads = assert_asyncapi_broadcast(params: {user_gid: @user.to_gid_param}) do
      @inventory.update_stock_item(stock_item, {name: "Iron"})
    end

    assert_equal @inventory.id, payloads.first["inventoryId"]
  end
end
