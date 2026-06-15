# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsRecurringSignupTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("mission_builder")
    travel_to Time.zone.parse("2026-05-13 20:00:00 UTC")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @event = create(:fleet_event, :open,
      fleet: @fleet, created_by: @admin,
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      timezone: "UTC",
      recurring: true, recurrence_interval: "weekly")
    sign_in @member
  end

  teardown do
    travel_back
  end

  test "requires an occurrence_date for recurring events" do
    post "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/signup",
      params: {status: "interested"}, as: :json

    assert_equal 422, response.status
    assert_equal "missing_occurrence_date", JSON.parse(response.body)["code"]
  end

  test "stores the occurrence_date on the signup" do
    post "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/signup",
      params: {status: "interested", occurrenceDate: "2026-05-21"},
      as: :json

    assert_equal 201, response.status, response.body
    membership = @fleet.fleet_memberships.find_by(user: @member)
    signup = FleetEventSignup.find_by(
      fleet_event_id: @event.id, fleet_membership_id: membership.id
    )
    assert_equal Date.parse("2026-05-21"), signup.occurrence_date
  end

  test "allows the same member to sign up for two different occurrences" do
    post "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/signup",
      params: {status: "interested", occurrenceDate: "2026-05-21"},
      as: :json
    assert_equal 201, response.status

    post "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/signup",
      params: {status: "interested", occurrenceDate: "2026-05-28"},
      as: :json
    assert_equal 201, response.status

    membership = @fleet.fleet_memberships.find_by(user: @member)
    assert_equal 2, FleetEventSignup.where(
      fleet_event_id: @event.id, fleet_membership_id: membership.id
    ).count
  end
end
