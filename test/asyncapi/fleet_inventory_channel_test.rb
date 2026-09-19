# frozen_string_literal: true

require "asyncapi_helper"

class FleetInventoryChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "fleet_inventory:{user_gid}", channel_class: FleetInventoryChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "Something in one of the user's fleets' stores changed" do
      operationId "receiveFleetInventoryUpdate"
      message ::Cable::V1::Schemas::FleetInventoryChangedMessage
    end
  end

  setup do
    @officer = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, officers: [@officer], members: [@member])
    @depot = create(:fleet_inventory, fleet: @fleet)
  end

  test "broadcasts to a member when an entry is added" do
    payloads = assert_asyncapi_broadcast(params: {user_gid: @member.to_gid_param}) do
      create(:fleet_inventory_item, fleet_inventory: @depot)
    end

    assert_equal @depot.id, payloads.first["inventoryId"]
    assert_equal @fleet.slug, payloads.first["fleetSlug"]
  end
end
