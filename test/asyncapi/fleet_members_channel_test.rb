# frozen_string_literal: true

require "asyncapi_helper"

class FleetMembersChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "fleet_members:{user_gid}", channel_class: FleetMembersChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "A membership in one of the user's fleets changed" do
      operationId "receiveFleetMembers"
      message ::V1::Schemas::Fleets::FleetMember
    end
  end
end
