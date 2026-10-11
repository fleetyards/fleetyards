# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("List Missions") do
      operationId "fleetMissions"
      tags "Missions"
      produces "application/json"

      parameter name: :archived, in: :query, schema: {type: :boolean}, required: false
      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::MissionQuery,
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Missions::MissionsList
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
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  # A draft is not a mission the fleet has been offered, so it stays off an
  # ordinary member's list until somebody publishes it.
  test "GET /fleets/:slug/missions hides another author's draft from a member" do
    create(:mission, fleet: @fleet, created_by: @admin)
    create(:mission, :draft, fleet: @fleet, created_by: @admin)
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 1, parsed_body["items"].size
      assert_equal ["published"], parsed_body["items"].map { |item| item["status"] }.uniq
    end
  end

  test "GET /fleets/:slug/missions shows a draft to the manager who can publish it" do
    create(:mission, :draft, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 1, parsed_body["items"].size
      assert_equal "draft", parsed_body["items"].first["status"]
    end
  end

  test "GET /fleets/:slug/missions returns the list" do
    create_list(:mission, 2, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 2, parsed_body["items"].size
    end
  end

  test "GET /fleets/:slug/missions reaches missions past the first page" do
    create_list(:mission, 31, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {page: 2} do
      assert_equal 1, parsed_body["items"].size
      assert_equal 2, parsed_body.dig("meta", "pagination", "totalPages")
    end
  end

  test "GET /fleets/:slug/missions honours perPage" do
    create_list(:mission, 3, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].size
    end
  end

  test "GET /fleets/:slug/missions filters by status" do
    published = create(:mission, fleet: @fleet, created_by: @admin)
    create(:mission, :draft, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {statusEq: "published"}} do
      assert_equal [published.slug], parsed_body["items"].map { |item| item["slug"] }
    end
  end

  test "GET /fleets/:slug/missions searches by title" do
    create(:mission, fleet: @fleet, created_by: @admin, title: "Jumptown Raid")
    create(:mission, fleet: @fleet, created_by: @admin, title: "Cargo Run")
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {titleCont: "jumptown"}} do
      assert_equal ["Jumptown Raid"], parsed_body["items"].map { |item| item["title"] }
    end
  end

  test "GET /fleets/:slug/missions sorts by title desc" do
    create(:mission, fleet: @fleet, created_by: @admin, title: "Alpha")
    create(:mission, fleet: @fleet, created_by: @admin, title: "Bravo")
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {s: "title desc"}} do
      assert_equal %w[Bravo Alpha], parsed_body["items"].map { |item| item["title"] }
    end
  end

  test "GET /fleets/:slug/missions with OAuth bearer token" do
    create_list(:mission, 1, fleet: @fleet, created_by: @admin)

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug/missions returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "GET /fleets/:slug/missions returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
