# frozen_string_literal: true

require "asyncapi_helper"

class UserPresenceChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "user_presence:{user_gid}", channel_class: UserPresenceChannel do
    parameter :user_gid,
      description: "GlobalID param of the subscribed user, derived from the connection",
      client_supplied: false

    broadcast "Somebody the user has an accepted relationship with came online or went offline" do
      operationId "receiveUserPresence"
      message ::Cable::V1::Schemas::UserPresenceMessage
    end
  end

  setup do
    UserPresence.reset!

    @user = create(:user)
    @co_member = create(:user)

    create(:fleet, officers: [@user], members: [@co_member])

    # The job reads the store rather than taking the value, so the subject has
    # to actually be connected.
    UserPresence.connect(@user.id, "tab-1")

    Flipper.enable(:online_status)
  end

  teardown do
    UserPresence.reset!
    Flipper.disable(:online_status)
  end

  test "broadcasts the transition to a co-member" do
    payloads = assert_asyncapi_broadcast(params: {user_gid: @co_member.to_gid_param}) do
      Presence::BroadcastTransitionJob.new.perform(@user.id)
    end

    assert_equal @user.id, payloads.first["userId"]
    assert payloads.first["online"]
  end

  test "broadcasts the transition to an accepted friend" do
    friend = create(:user)
    create(:friendship, :accepted, requester: friend, addressee: @user)

    payloads = assert_asyncapi_broadcast(params: {user_gid: friend.to_gid_param}) do
      Presence::BroadcastTransitionJob.new.perform(@user.id)
    end

    assert_equal @user.id, payloads.first["userId"]
  end
end
