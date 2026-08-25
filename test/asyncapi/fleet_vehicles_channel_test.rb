# frozen_string_literal: true

require "asyncapi_helper"

class FleetVehiclesChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "fleet_vehicles:{user_gid}", channel_class: FleetVehiclesChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A fleet member's vehicles changed" do
      operationId "receiveFleetVehicles"
      message ::V1::Schemas::Fleets::FleetMember
    end
  end
end
