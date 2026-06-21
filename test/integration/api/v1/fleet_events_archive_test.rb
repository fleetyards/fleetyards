# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventsArchiveTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    sign_in @admin
  end

  test "DELETE /fleets/:slug/events/:event archives a non-archived event instead of destroying it" do
    delete "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}", as: :json

    assert_equal 200, response.status
    assert @event.reload.archived?
  end

  test "DELETE /fleets/:slug/events/:event destroys an already-archived event" do
    @event.archive!

    delete "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}", as: :json

    assert_equal 204, response.status
    refute FleetEvent.exists?(@event.id)
  end

  test "PUT /fleets/:slug/events/:event/unarchive restores an archived event" do
    @event.archive!

    put "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/unarchive", as: :json

    assert_equal 200, response.status
    refute @event.reload.archived?
  end

  test "PUT /fleets/:slug/events/:event/unarchive returns 400 when the event is not archived" do
    put "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/unarchive", as: :json

    assert_equal 400, response.status
  end

  test "GET /fleets/:slug/events hides archived events by default" do
    @event.archive!
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin)

    get "/api/v1/fleets/#{@fleet.slug}/events", as: :json

    assert_equal 200, response.status
    ids = JSON.parse(response.body)["items"].map { |e| e["id"] }
    refute_includes ids, @event.id
  end

  test "GET /fleets/:slug/events returns archived events with archived=true" do
    @event.archive!

    get "/api/v1/fleets/#{@fleet.slug}/events", params: {archived: "true"}, as: :json

    assert_equal 200, response.status
    ids = JSON.parse(response.body)["items"].map { |e| e["id"] }
    assert_includes ids, @event.id
  end
end
