# frozen_string_literal: true

require "test_helper"

class Api::V1::MeCalendarSubscriptionIcsTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("mission_builder")
    @user = create(:user)
    @fleet = create(:fleet, members: [@user])
    @other_user = create(:user)
    @other_fleet = create(:fleet, members: [@other_user])
    @user.ensure_calendar_feed_token!
  end

  def signup_for(membership, event, status: "confirmed")
    create(:fleet_event_signup,
      fleet_event: event, fleet_membership: membership,
      fleet_event_slot: nil, status: status)
  end

  test "returns only events the user has signed up for" do
    membership = @fleet.fleet_memberships.find_by(user: @user)
    mine = create(:fleet_event, :open, fleet: @fleet, title: "My Op",
      starts_at: 2.days.from_now)
    not_mine = create(:fleet_event, :open, fleet: @fleet, title: "Other Op",
      starts_at: 2.days.from_now)
    signup_for(membership, mine)

    get "/api/v1/me/calendar/events.ics", params: {token: @user.calendar_feed_token}

    assert_response :ok
    assert_equal "text/calendar", response.media_type
    assert_includes response.body, "My Op"
    refute_includes response.body, "Other Op"
    assert not_mine.present?
  end

  test "scopes to the user's own signups (not other users')" do
    other_membership = @other_fleet.fleet_memberships.find_by(user: @other_user)
    theirs = create(:fleet_event, :open, fleet: @other_fleet,
      title: "Their Op", starts_at: 2.days.from_now)
    signup_for(other_membership, theirs)

    get "/api/v1/me/calendar/events.ics", params: {token: @user.calendar_feed_token}

    assert_response :ok
    refute_includes response.body, "Their Op"
  end

  test "returns 403 with no token" do
    get "/api/v1/me/calendar/events.ics"

    assert_response :forbidden
  end

  test "returns 403 with a wrong token" do
    get "/api/v1/me/calendar/events.ics", params: {token: "nope"}

    assert_response :forbidden
  end
end
