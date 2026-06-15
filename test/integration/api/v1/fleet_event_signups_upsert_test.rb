# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventSignupsUpsertTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    @team = create(:fleet_event_team, fleet_event: @event)
    @slot = create(:fleet_event_slot, slottable: @team)
    sign_in @member
  end

  test "POST /fleets/:fleet/events/:slug/signup creates an interested signup by default" do
    post "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/signup", params: {}, as: :json

    assert_equal 201, response.status
    assert_equal "interested", JSON.parse(response.body)["status"]
  end

  test "POST /fleets/:fleet/events/:slug/signup upserts existing event-level signup to a different status" do
    post "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/signup", params: {status: "interested"}, as: :json
    assert_equal 201, response.status

    post "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/signup", params: {status: "tentative"}, as: :json
    assert_equal 200, response.status
    assert_equal "tentative", JSON.parse(response.body)["status"]

    membership = @fleet.fleet_memberships.find_by(user: @member)
    assert_equal 1, @event.fleet_event_signups.where(fleet_membership: membership).where.not(status: "withdrawn").count
  end

  test "POST /fleets/:fleet/events/:slug/signup returns 409 when the member is already in a slot" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: membership, status: "confirmed")

    post "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/signup", params: {status: "interested"}, as: :json

    assert_equal 409, response.status
  end

  test "POST /fleet-event-slots/:id/signup promotes an existing event-level signup onto the slot" do
    post "/api/v1/fleets/#{@fleet.slug}/events/#{@event.slug}/signup", params: {status: "interested"}, as: :json
    assert_equal 201, response.status

    post "/api/v1/fleet-event-slots/#{@slot.id}/signup", params: {status: "confirmed"}, as: :json
    assert_equal 200, response.status
    data = JSON.parse(response.body)
    assert_equal "confirmed", data["status"]
    assert_equal @slot.id, data["fleetEventSlotId"]

    membership = @fleet.fleet_memberships.find_by(user: @member)
    assert_equal 1, @event.fleet_event_signups.where(fleet_membership: membership).where.not(status: "withdrawn").count
  end

  test "POST /fleet-event-slots/:id/signup coerces tentative requests to confirmed when binding to a slot" do
    post "/api/v1/fleet-event-slots/#{@slot.id}/signup", params: {status: "tentative"}, as: :json

    assert_equal 201, response.status
    assert_equal "confirmed", JSON.parse(response.body)["status"]
  end

  test "POST /fleet-event-slots/:id/signup returns 409 when the member is already in a different slot" do
    other_slot = create(:fleet_event_slot, slottable: @team)
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: other_slot, fleet_membership: membership, status: "confirmed")

    post "/api/v1/fleet-event-slots/#{@slot.id}/signup", params: {status: "confirmed"}, as: :json

    assert_equal 409, response.status
  end

  test "POST /fleet-event-slots/:id/signup rejects signups when the event is past" do
    @event.update!(starts_at: 2.hours.ago, ends_at: 1.hour.ago)

    post "/api/v1/fleet-event-slots/#{@slot.id}/signup", params: {status: "confirmed"}, as: :json

    assert_includes [403, 400], response.status
  end

  test "PATCH /fleet-event-signups/:id/assign assigns an unassigned signup to a slot and promotes it to confirmed" do
    other_member = create(:user)
    other_membership = create(:fleet_membership, fleet: @fleet, user: other_member, aasm_state: "accepted")
    signup = create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, fleet_membership: other_membership, status: "interested")

    sign_out @member
    sign_in @admin

    patch "/api/v1/fleet-event-signups/#{signup.id}/assign",
      params: {fleetEventSlotId: @slot.id},
      as: :json

    assert_equal 200, response.status, "got #{response.status}: #{response.body}"
    data = JSON.parse(response.body)
    assert_equal @slot.id, data["fleetEventSlotId"]
    assert_equal "confirmed", data["status"]
  end
end
