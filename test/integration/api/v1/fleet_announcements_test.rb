# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetAnnouncementsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  COLLECTION_PATH = "/fleets/{fleetSlug}/announcements"
  MEMBER_PATH = "/fleets/{fleetSlug}/announcements/{id}"

  api_path COLLECTION_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Fleet Announcements") do
      operationId "fleetAnnouncements"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Announcements::FleetAnnouncementsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    post("Create Fleet Announcement") do
      operationId "createFleetAnnouncement"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetAnnouncementInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Fleets::Announcements::FleetAnnouncement
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path MEMBER_PATH do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    put("Update Fleet Announcement") do
      operationId "updateFleetAnnouncement"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetAnnouncementInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Announcements::FleetAnnouncement
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    delete("Delete Fleet Announcement") do
      operationId "destroyFleetAnnouncement"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful")

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:user)
    @officer = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], officers: [@officer], members: [@member])
  end

  test "GET announcements shows a member what is still standing, newest first" do
    create(:fleet_announcement, fleet: @fleet, author: @officer, body: "Old news", created_at: 2.days.ago)
    create(:fleet_announcement, fleet: @fleet, author: @officer, body: "Ops moved to Friday", created_at: 1.hour.ago)
    create(:fleet_announcement, fleet: @fleet, author: @officer, body: "Expired", expires_at: 1.hour.ago)

    sign_in @member
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["Ops moved to Friday", "Old news"], parsed_body["items"].map { |item| item["body"] }
      assert_equal @officer.username, parsed_body["items"].first.dig("author", "username")
    end
  end

  test "GET announcements is refused to somebody outside the fleet" do
    sign_in create(:user)

    get "/api/v1/fleets/#{@fleet.slug}/announcements"

    assert_includes [403, 404], response.status
  end

  test "POST announcements lets an officer post one" do
    sign_in @officer

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug},
      body: {body: "Welcome aboard", expiresAt: 3.days.from_now.iso8601} do
      assert_equal "Welcome aboard", parsed_body["body"]
      assert_equal @officer.username, parsed_body.dig("author", "username")
    end
  end

  test "POST announcements refuses a plain member" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug}, body: {body: "Hello"}
  end

  test "POST announcements refuses an empty body" do
    sign_in @officer

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}, body: {body: ""}
  end

  test "PUT announcement lets an officer edit it" do
    announcement = create(:fleet_announcement, fleet: @fleet, author: @admin)

    sign_in @officer
    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug, id: announcement.id},
      body: {body: "Corrected", expiresAt: nil} do
      assert_equal "Corrected", parsed_body["body"]
    end
  end

  test "PUT announcement refuses a plain member" do
    announcement = create(:fleet_announcement, fleet: @fleet, author: @admin)

    sign_in @member
    assert_api_response :put, 403, path_params: {fleetSlug: @fleet.slug, id: announcement.id},
      body: {body: "Mine now"}
  end

  test "DELETE announcement lets an officer take it down" do
    announcement = create(:fleet_announcement, fleet: @fleet, author: @admin)

    sign_in @officer
    assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug, id: announcement.id}

    refute FleetAnnouncement.exists?(announcement.id)
  end

  test "DELETE announcement refuses a plain member" do
    announcement = create(:fleet_announcement, fleet: @fleet, author: @admin)

    sign_in @member
    assert_api_response :delete, 403, path_params: {fleetSlug: @fleet.slug, id: announcement.id}
  end
end
