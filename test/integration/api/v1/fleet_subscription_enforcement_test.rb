# frozen_string_literal: true

require "test_helper"

# Enforcement across the four premium capabilities, and the three things that
# must *not* change: a flag that is off still answers `forbidden`, personal
# surfaces stay free, and none of it happens at all while the rollout flag is
# off.
class Api::V1::FleetSubscriptionEnforcementTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @fleet = create(:fleet, admins: [@user])

    %w[fleet_contracts fleet_mission_builder fleet_logistics fleet_tours
      tour_payouts hangar_inventories ship_inventories].each { |flag| Flipper.enable(flag) }
  end

  # Not an openapi_ruby spec -- this asserts behaviour across 28 controllers
  # rather than documenting one endpoint, so it parses its own responses.
  private def body_code
    JSON.parse(response.body)["code"]
  rescue JSON::ParserError
    nil
  end

  private def subscribe!
    create(:fleet_subscription, fleet: @fleet)
  end

  private def surfaces
    {
      contracts: "/api/v1/fleets/#{@fleet.slug}/contracts",
      events: "/api/v1/fleets/#{@fleet.slug}/events",
      logistics: "/api/v1/fleets/#{@fleet.slug}/inventories",
      tours: "/api/v1/fleets/#{@fleet.slug}/tours"
    }
  end

  # The whole point of shipping this before the announcement: with the rollout
  # flag off, nothing about the four capabilities changes for anybody.
  test "nothing is enforced while the rollout flag is off" do
    Flipper.disable("fleet_subscriptions")
    sign_in @user

    surfaces.each do |capability, path|
      get path

      assert_response :success,
        "#{capability} did not answer normally although enforcement is not rolled out"
    end
  end

  test "an unsubscribed fleet is refused once it is rolled out" do
    Flipper.enable("fleet_subscriptions")
    sign_in @user

    surfaces.each do |capability, path|
      get path

      assert_equal 403, response.status, "#{capability} was not enforced"
      assert_equal "subscription_required", body_code,
        "#{capability} answered the wrong code"
    end
  end

  test "a subscribed fleet reaches all four" do
    Flipper.enable("fleet_subscriptions")
    subscribe!
    sign_in @user

    surfaces.each do |capability, path|
      get path

      assert_response :success, "#{capability} was refused for a subscribed fleet"
    end
  end

  # The order carries meaning: a capability that is not rolled out answers
  # "not available" to everyone, subscribed or not. Reversed, a fleet would be
  # sold something it cannot yet have.
  test "a capability that is off still answers forbidden, not an upsell" do
    Flipper.enable("fleet_subscriptions")
    Flipper.disable("fleet_contracts")
    sign_in @user

    get surfaces[:contracts]

    assert_equal 403, response.status
    assert_equal "forbidden", body_code,
      "an unrolled feature must not be sold"
  end

  test "the capability check runs before the subscription one even when subscribed" do
    Flipper.enable("fleet_subscriptions")
    Flipper.disable("fleet_logistics")
    subscribe!
    sign_in @user

    get surfaces[:logistics]

    assert_equal "forbidden", body_code
  end

  # D3: the personal surfaces are not what a fleet subscription buys.
  test "a standalone tour stays free of the fleet subscription" do
    Flipper.enable("fleet_subscriptions")
    tour = create(:tour, created_by: @user)
    sign_in @user

    get "/api/v1/tours/#{tour.slug}"

    assert_response :success, "the personal tour tool must not be paywalled"
  end

  test "a standalone tour's ledger stays free too" do
    Flipper.enable("fleet_subscriptions")
    tour = create(:tour, created_by: @user)
    ledger = create(:payout_ledger, subject: tour)
    create(:payout_participant, payout_ledger: ledger, user: @user)
    sign_in @user

    get "/api/v1/payouts/#{ledger.id}/entries"

    assert_response :success, "the personal ledger must not be paywalled"
  end

  test "a member's own hangar inventory is untouched" do
    Flipper.enable("fleet_subscriptions")
    sign_in @user

    get "/api/v1/hangar/inventories"

    assert_response :success, "a personal inventory is not a fleet feature"
  end

  # An unsubscribed fleet is still a fleet.
  test "the free tier still works without a subscription" do
    Flipper.enable("fleet_subscriptions")
    sign_in @user

    ["/api/v1/fleets/#{@fleet.slug}",
      "/api/v1/fleets/#{@fleet.slug}/members",
      "/api/v1/fleets/#{@fleet.slug}/vehicles"].each do |path|
      get path

      assert_response :success, "#{path} is free and must stay reachable"
    end
  end

  test "a lapsed subscription stops granting with nothing having run" do
    Flipper.enable("fleet_subscriptions")
    create(:fleet_subscription, fleet: @fleet, started_at: Date.current - 30,
      ended_at: Date.current - 1)
    sign_in @user

    get surfaces[:contracts]

    assert_equal "subscription_required", body_code
  end

  # Enabling for one fleet enforces there first rather than everywhere at once.
  test "the rollout can be switched on for a single fleet" do
    other = create(:fleet, admins: [@user])
    Flipper.enable_actor("fleet_subscriptions", @fleet)
    sign_in @user

    get surfaces[:contracts]
    assert_equal "subscription_required", body_code

    get "/api/v1/fleets/#{other.slug}/contracts"
    assert_response :success, "a fleet without the gate is not enforced yet"
  end

  test "the refusal is translated in every locale" do
    I18n.available_locales.each do |locale|
      assert I18n.t(:"messages.subscription_required", locale:, default: nil, fallback: false),
        "no #{locale} translation"
    end
  end

  # Every one of these reached the concern with no fleet and skipped enforcement
  # entirely, because the guard that keeps personal surfaces free treats a
  # missing fleet as "nothing to enforce". They are the actions that load their
  # fleet from something other than the path.
  test "sorting event slots is enforced" do
    Flipper.enable("fleet_subscriptions")
    event = create(:fleet_event, :active, fleet: @fleet, created_by: @user)
    team = create(:fleet_event_team, fleet_event: event)
    sign_in @user

    put "/api/v1/fleet-event-slots/sort",
      params: {slottableType: "FleetEventTeam", slottableId: team.id, sorting: []}.to_json,
      headers: {"CONTENT_TYPE" => "application/json"}

    assert_equal "subscription_required", body_code
  end

  test "sorting mission slots is enforced" do
    Flipper.enable("fleet_subscriptions")
    mission = create(:mission, fleet: @fleet, created_by: @user)
    team = create(:mission_team, mission:)
    sign_in @user

    put "/api/v1/mission-slots/sort",
      params: {slottableType: "MissionTeam", slottableId: team.id, sorting: []}.to_json,
      headers: {"CONTENT_TYPE" => "application/json"}

    assert_equal "subscription_required", body_code
  end

  # A token already issued would otherwise serve the whole feed forever.
  test "the calendar feed stops when the subscription lapses" do
    Flipper.enable("fleet_subscriptions")
    @fleet.ensure_calendar_feed_token!
    token = @fleet.reload.calendar_feed_token

    get "/api/v1/fleets/#{@fleet.slug}/events.ics", params: {token:}

    assert_response :forbidden
  end

  test "the calendar feed works for a subscribed fleet" do
    Flipper.enable("fleet_subscriptions")
    subscribe!
    @fleet.ensure_calendar_feed_token!
    token = @fleet.reload.calendar_feed_token

    get "/api/v1/fleets/#{@fleet.slug}/events.ics", params: {token:}

    assert_response :success
  end

  test "a fleet inventory transfer is enforced" do
    Flipper.enable("fleet_subscriptions")
    Flipper.enable("inventory_transfers")
    sign_in @user

    get "/api/v1/fleets/#{@fleet.slug}/inventory-transfers"

    assert_equal "subscription_required", body_code
  end

  test "a slug-addressed tour is enforced" do
    Flipper.enable("fleet_subscriptions")
    tour = create(:tour, fleet: @fleet, created_by: @user)
    sign_in @user

    get "/api/v1/tours/#{tour.slug}"

    assert_equal "subscription_required", body_code,
      "a fleet's tour carries no fleet in the path, and must still be enforced"
  end

  # Both PayoutLedgerScoped and FleetSubscriptionConcern define
  # `subscription_fleet`, and the concern is included last -- so its `@fleet`
  # default, nil on these controllers, won the lookup and skipped enforcement.
  test "a fleet event ledger's children are enforced" do
    Flipper.enable("fleet_subscriptions")
    event = create(:fleet_event, :active, fleet: @fleet, created_by: @user)
    ledger = create(:payout_ledger, subject: event)
    sign_in @user

    get "/api/v1/payouts/#{ledger.id}/entries"
    assert_equal "subscription_required", body_code, "entries"

    get "/api/v1/payouts/#{ledger.id}/participants"
    assert_equal "subscription_required", body_code, "participants"

    get "/api/v1/payouts/#{ledger.id}/transfers"
    assert_equal "subscription_required", body_code, "transfers"
  end

  test "a subscribed fleet reaches its ledger's children" do
    Flipper.enable("fleet_subscriptions")
    subscribe!
    event = create(:fleet_event, :active, fleet: @fleet, created_by: @user)
    ledger = create(:payout_ledger, subject: event)
    sign_in @user

    get "/api/v1/payouts/#{ledger.id}/entries"

    assert_response :success
  end

  # The capability comes first everywhere, including the feed -- checking only
  # the subscription would have served a subscribed fleet a feature the flag
  # says does not exist.
  test "the calendar feed answers the capability before the subscription" do
    Flipper.enable("fleet_subscriptions")
    Flipper.disable("fleet_mission_builder")
    subscribe!
    @fleet.ensure_calendar_feed_token!
    token = @fleet.reload.calendar_feed_token

    get "/api/v1/fleets/#{@fleet.slug}/events.ics", params: {token:}

    assert_response :forbidden,
      "a capability that is off is unavailable to a subscribed fleet too"
  end
end
