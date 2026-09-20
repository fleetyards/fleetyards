# frozen_string_literal: true

require "test_helper"

# Lives outside test/integration/api/v1 on purpose: it asserts who is told what
# about presence rather than a documented response shape, so it must not
# contribute to the generated OpenAPI schema.
#
# A list arriving over REST needs the current online set in the payload, or the
# dot is wrong until the first transition lands.
class OnlineStatusPayloadTest < ActionDispatch::IntegrationTest
  setup do
    UserPresence.reset!

    @reader = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@reader], members: [@member])

    UserPresence.connect(@member.id, "tab-1")

    Flipper.enable(:online_status)
    Flipper.enable(:friends)
    sign_in @reader
  end

  teardown do
    UserPresence.reset!
    Flipper.disable(:online_status)
    Flipper.disable(:friends)
  end

  def roster_row_for(user)
    get "/api/v1/fleets/#{@fleet.slug}/members", as: :json

    assert_equal 200, response.status

    JSON.parse(response.body)["items"].find { |row| row["userId"] == user.id }
  end

  test "a roster carries the dot for a connected co-member" do
    assert_equal true, roster_row_for(@member)["online"]
  end

  test "a roster reads offline for a co-member with no connection" do
    assert_equal false, roster_row_for(@reader)["online"]
  end

  test "the field is absent entirely with the flag off" do
    Flipper.disable(:online_status)

    refute roster_row_for(@member).key?("online")
  end

  test "a co-member who opted out reads offline" do
    @member.update!(show_online_status: false)

    assert_equal false, roster_row_for(@member)["online"]
  end

  test "an accepted friend carries presence and last activity" do
    friend = create(:user, last_active_at: 3.minutes.ago)
    create(:friendship, :accepted, requester: friend, addressee: @reader)
    UserPresence.connect(friend.id, "phone")

    get "/api/v1/friends", params: {state: "accepted"}, as: :json

    assert_equal 200, response.status

    row = JSON.parse(response.body)["items"].first["user"]

    assert_equal true, row["online"]
    assert row["lastActiveAt"].present?
  end

  test "an unanswered friendship carries neither" do
    asker = create(:user, last_active_at: 3.minutes.ago)
    create(:friendship, requester: asker, addressee: @reader)
    UserPresence.connect(asker.id, "phone")

    get "/api/v1/friends", params: {state: "pending"}, as: :json

    assert_equal 200, response.status

    row = JSON.parse(response.body)["items"].first["user"]

    refute row.key?("online")
    refute row.key?("lastActiveAt")
  end
end
