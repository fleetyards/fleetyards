# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeFleetsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/fleets" do
    get("My fleets at a glance") do
      operationId "myFleetSummaries"
      tags "Me"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:read"]},
        {OpenId: ["user", "user:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::MyFleetSummariesList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    UserPresence.reset!
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    create(:fleet_membership, :accepted, fleet: @fleet, user: @member)
  end

  teardown do
    UserPresence.reset!
  end

  test "GET /me/fleets returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /me/fleets summarises every fleet the reader has joined" do
    friend = create(:user)
    create(:fleet_membership, :accepted, fleet: @fleet, user: friend)
    UserPresence.connect(friend.id, "tab-friend")
    UserPresence.connect(@member.id, "tab-member")
    create(:fleet_announcement, fleet: @fleet, body: "**Hauling rates** change on Friday.", created_at: 1.hour.ago)
    create(:fleet_announcement, fleet: @fleet, body: "Older news", created_at: 2.days.ago)

    sign_in @member

    assert_api_response :get, 200 do
      summary = parsed_body["items"].sole

      assert_equal @fleet.slug, summary["slug"]
      assert_equal 3, summary["memberCount"]
      assert_equal "Hauling rates change on Friday.", summary.dig("latestAnnouncement", "excerpt")
    end
  end

  test "GET /me/fleets answers the counts only to a role that can act on them" do
    create(:fleet_membership, :requested, fleet: @fleet, user: create(:user))

    sign_in @admin
    assert_api_response :get, 200 do
      summary = parsed_body["items"].sole

      assert_equal 1, summary["pendingJoinRequestsCount"]
      assert summary.key?("onlineCount")
    end

    sign_in @member
    assert_api_response :get, 200 do
      summary = parsed_body["items"].sole

      assert_not summary.key?("pendingJoinRequestsCount")
      assert_not summary.key?("pendingTransfersCount")
    end
  end

  test "GET /me/fleets leaves out fleets the reader was only invited to" do
    create(:fleet_membership, :invited, fleet: create(:fleet, admins: [create(:user)]), user: @member)

    sign_in @member

    assert_api_response :get, 200 do
      assert_equal [@fleet.slug], parsed_body["items"].pluck("slug")
    end
  end
end
