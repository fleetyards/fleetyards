# frozen_string_literal: true

require "test_helper"

class Api::V1::NotificationsRecordBehaviourTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  def notification_record
    get "/api/v1/notifications", as: :json

    assert_response :ok

    JSON.parse(response.body)["items"].first["record"]
  end

  test "a membership notification points at the membership with the slugs to load it" do
    fleet = create(:fleet, admins: [create(:user)])
    membership = fleet.fleet_memberships.create!(user: @user, fleet_role: fleet.default_member_role)

    create(:notification, user: @user, notification_type: "fleet_invite", record: membership)

    record = notification_record

    assert_equal "fleet_membership", record["type"]
    assert_equal membership.id, record["id"]
    assert_equal fleet.slug, record["fleetSlug"]
    assert_equal @user.username, record["username"]
  end

  test "an event notification carries both slugs" do
    fleet = create(:fleet, admins: [@user])
    event = create(:fleet_event, fleet:, created_by: @user)

    create(:notification, user: @user, notification_type: "fleet_event_published", record: event)

    record = notification_record

    assert_equal "fleet_event", record["type"]
    assert_equal fleet.slug, record["fleetSlug"]
    assert_equal event.slug, record["eventSlug"]
  end

  test "a hangar sync notification points at the import" do
    import = Imports::HangarSync.create!(user: @user)

    create(:notification, user: @user, notification_type: "hangar_sync_failed", record: import)

    record = notification_record

    assert_equal "hangar_sync", record["type"]
    assert_equal import.id, record["id"]
  end

  # `Jbuilder.ignore_nil` is on for the whole API, so a notification about
  # nothing in particular leaves the key out rather than sending a null.
  test "a notification without a record carries no reference" do
    create(:notification, user: @user, notification_type: "hangar_create", record: nil)

    get "/api/v1/notifications", as: :json

    refute JSON.parse(response.body)["items"].first.key?("record")
  end

  test "a page of notifications does not query per row for its references" do
    fleet = create(:fleet, admins: [create(:user)])

    3.times do
      membership = fleet.fleet_memberships.create!(user: create(:user), fleet_role: fleet.default_member_role)
      create(:notification, user: @user, notification_type: "fleet_member_requested", record: membership)
    end

    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      queries << payload[:sql] unless payload[:name].in?(["SCHEMA", "TRANSACTION"])
    end

    get "/api/v1/notifications", as: :json

    ActiveSupport::Notifications.unsubscribe(subscriber)

    # One for the memberships, one for their fleets, one for their users -
    # three rows must not cost three of each.
    fleet_queries = queries.count { |sql| sql.include?('FROM "fleets"') }

    assert_operator fleet_queries, :<=, 1, "expected the fleets to be preloaded, got #{fleet_queries} queries"
  end
end
