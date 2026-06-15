# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsUpdateOccurrenceTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @event = create(:fleet_event, :open,
      fleet: @fleet, created_by: @admin,
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      timezone: "UTC", location: "Stanton",
      recurring: true, recurrence_interval: "weekly")
    sign_in @admin
  end

  test "creates a per-occurrence state row with the override fields" do
    patch "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/update-occurrence",
      params: {date: "2026-05-21", location: "Levski", scenario: "Bunker raid"},
      as: :json

    assert_equal 200, response.status, response.body
    state = @event.reload.fleet_event_occurrence_states.find_by(
      occurrence_date: Date.parse("2026-05-21")
    )
    assert_equal "Levski", state.location
    assert_equal "Bunker raid", state.scenario
  end

  test "updates an existing state row" do
    create(:fleet_event_occurrence_state,
      fleet_event: @event, occurrence_date: Date.parse("2026-05-21"),
      location: "Levski")

    patch "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/update-occurrence",
      params: {date: "2026-05-21", location: "Yela"},
      as: :json

    assert_equal 200, response.status, response.body
    assert_equal "Yela", @event.fleet_event_occurrence_states.first.reload.location
  end

  test "rejects when the event is not recurring" do
    one_off = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)

    patch "/api/v1/fleets/#{@fleet.slug}/events/#{one_off.slug}/update-occurrence",
      params: {date: "2026-05-21", location: "Levski"},
      as: :json

    assert_equal 422, response.status
  end

  test "rejects when date is missing" do
    patch "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/update-occurrence",
      params: {location: "Levski"},
      as: :json

    assert_equal 400, response.status
  end
end
