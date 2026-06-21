# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventSlotsRecurringSignupTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("mission_builder")
    travel_to Time.zone.parse("2026-05-13 20:00:00 UTC")
    @admin = create(:user)
    @alice = create(:user)
    @bob = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@alice, @bob])
    @event = create(:fleet_event, :open,
      fleet: @fleet, created_by: @admin,
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      timezone: "UTC",
      recurring: true, recurrence_interval: "weekly")
    @team = create(:fleet_event_team, fleet_event: @event)
    @slot = create(:fleet_event_slot, slottable: @team, title: "Pilot")
  end

  teardown do
    travel_back
  end

  test "allows two different members in the same slot on different occurrences" do
    sign_in @alice
    post "/api/v1/fleet-event-slots/#{@slot.id}/signup",
      params: {status: "confirmed", occurrenceDate: "2026-05-21"},
      as: :json
    assert_equal 201, response.status, response.body

    sign_out @alice
    sign_in @bob
    post "/api/v1/fleet-event-slots/#{@slot.id}/signup",
      params: {status: "confirmed", occurrenceDate: "2026-05-28"},
      as: :json
    assert_equal 201, response.status, response.body

    assert_equal 2, @slot.fleet_event_signups.count
  end

  test "still blocks two members claiming the same slot on the same occurrence" do
    sign_in @alice
    post "/api/v1/fleet-event-slots/#{@slot.id}/signup",
      params: {status: "confirmed", occurrenceDate: "2026-05-21"},
      as: :json
    assert_equal 201, response.status

    sign_out @alice
    sign_in @bob
    post "/api/v1/fleet-event-slots/#{@slot.id}/signup",
      params: {status: "confirmed", occurrenceDate: "2026-05-21"},
      as: :json

    assert_includes [400, 422], response.status
  end

  test "requires occurrenceDate for recurring slot signups" do
    sign_in @alice
    post "/api/v1/fleet-event-slots/#{@slot.id}/signup",
      params: {status: "confirmed"},
      as: :json

    assert_equal 422, response.status
  end
end
