# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeEventsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/events" do
    get("My agenda") do
      operationId "myEvents"
      tags "Me"
      produces "application/json"

      parameter name: :from, in: :query, schema: {type: :string, format: "date-time"}, required: false
      parameter name: :to, in: :query, schema: {type: :string, format: "date-time"}, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:read"]},
        {OpenId: ["user", "user:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::MyEventsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    create(:fleet_membership, :accepted, fleet: @fleet, user: @member)
  end

  test "GET /me/events returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /me/events merges fleet events and game events, soonest first" do
    other_fleet = create(:fleet, admins: [create(:user)])
    create(:fleet_membership, :accepted, fleet: other_fleet, user: @member)

    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Cargo run", starts_at: 3.days.from_now)
    create(:fleet_event, :open, fleet: other_fleet, created_by: @admin, title: "Mining op", starts_at: 1.day.from_now)
    create(:game_event, title: "Launch week", starts_at: 2.days.ago, ends_at: 5.days.from_now)

    sign_in @member

    assert_api_response :get, 200 do
      items = parsed_body["items"]

      assert_equal %w[game_event fleet_event fleet_event], items.pluck("type")
      assert_equal "Launch week", items[0].dig("gameEvent", "title")
      assert_equal ["Mining op", other_fleet.slug], [items[1].dig("fleetEvent", "title"), items[1].dig("fleet", "slug")]
      assert_equal "Cargo run", items[2].dig("fleetEvent", "title")
    end
  end

  # A summary is for everybody in the fleet: what the officers are still
  # drafting, or kept to themselves, belongs on the fleet's own calendar.
  test "GET /me/events leaves drafts and officers-only events to those who run events" do
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Announced", starts_at: 1.day.from_now)
    create(:fleet_event, fleet: @fleet, created_by: @admin, title: "Draft", starts_at: 2.days.from_now)
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Officers", starts_at: 3.days.from_now,
      visibility: "officers")

    sign_in @member
    assert_api_response :get, 200 do
      assert_equal ["Announced"], parsed_body["items"].map { |item| item.dig("fleetEvent", "title") }
    end

    sign_in @admin
    assert_api_response :get, 200 do
      assert_equal %w[Announced Draft Officers], parsed_body["items"].map { |item| item.dig("fleetEvent", "title") }
    end
  end

  test "GET /me/events leaves out squadron events the reader is not in" do
    squadron = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Squadron only",
      starts_at: 1.day.from_now, visibility: "squadron", fleet_squadrons: [squadron])

    sign_in @member

    assert_api_response :get, 200 do
      assert_empty parsed_body["items"]
    end
  end

  test "GET /me/events skips fleets the mission builder is not rolled out to" do
    Flipper.disable("fleet_mission_builder")
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, starts_at: 1.day.from_now)

    sign_in @member

    assert_api_response :get, 200 do
      assert_empty parsed_body["items"]
    end
  end

  test "GET /me/events carries the reader's own signup" do
    event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin, starts_at: 1.day.from_now)
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event: event, fleet_event_slot: nil, fleet_membership: membership, status: "confirmed")

    sign_in @member

    assert_api_response :get, 200 do
      assert_equal "confirmed", parsed_body["items"].first.dig("fleetEvent", "viewerSignup", "status")
    end
  end

  test "GET /me/events ignores fleets the reader has only been invited to" do
    invited_to = create(:fleet, admins: [create(:user)])
    create(:fleet_membership, :invited, fleet: invited_to, user: @member)
    create(:fleet_event, :open, fleet: invited_to, created_by: @admin, starts_at: 1.day.from_now)

    sign_in @member

    assert_api_response :get, 200 do
      assert_empty parsed_body["items"]
    end
  end
end
